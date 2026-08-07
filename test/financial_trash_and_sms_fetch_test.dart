import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:note_taking_app/data/database_helper.dart';
import 'package:note_taking_app/data/transaction_model.dart';
import 'package:note_taking_app/features/finances/data/transaction_repository.dart';
import 'package:note_taking_app/services/sms_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Financial Trash & Tombstones Unit Tests', () {
    late Database db;
    late TransactionRepository repo;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 19,
        onCreate: (db, version) async {
          await DatabaseHelper.instance.createTestDatabase(db);
        },
      );
      DatabaseHelper.setMockDatabase(db);
      repo = TransactionRepository.instance;
    });

    tearDown(() async {
      await db.close();
      DatabaseHelper.setMockDatabase(null);
    });

    test('Soft deleting a transaction moves it to Trash and excludes from active readAllTransactions', () async {
      final txn = await repo.createTransaction(
        TransactionModel(
          amount: 1500,
          description: 'Supermarket Purchase',
          date: DateTime.now(),
          isExpense: true,
          category: 'Groceries',
          smsId: 'test_sms_1001',
        ),
      );
      expect(txn.id, isNotNull);

      final activeBefore = await repo.readAllTransactions();
      expect(activeBefore.any((t) => t.id == txn.id), isTrue);

      await repo.softDeleteTransaction(txn.id!);

      final activeAfter = await repo.readAllTransactions();
      expect(activeAfter.any((t) => t.id == txn.id), isFalse);

      final trashed = await repo.readTrashedTransactions();
      expect(trashed.any((t) => t.id == txn.id), isTrue);
      expect(trashed.firstWhere((t) => t.id == txn.id).deletedAt, isNotNull);
    });

    test('smsExists returns true for soft-deleted transactions to prevent re-importing', () async {
      final txn = await repo.createTransaction(
        TransactionModel(
          amount: 2500,
          description: 'Dining Expense',
          date: DateTime.now(),
          isExpense: true,
          category: 'Food',
          smsId: 'test_sms_2002',
        ),
      );

      await repo.softDeleteTransaction(txn.id!);

      final exists = await repo.smsExists('test_sms_2002');
      expect(exists, isTrue, reason: 'SMS fetch must NOT re-import soft-deleted transactions');
    });

    test('Restoring a trashed transaction returns it to active ledger', () async {
      final txn = await repo.createTransaction(
        TransactionModel(
          amount: 800,
          description: 'Coffee Shop',
          date: DateTime.now(),
          isExpense: true,
          category: 'Food',
          smsId: 'test_sms_3003',
        ),
      );

      await repo.softDeleteTransaction(txn.id!);
      expect((await repo.readAllTransactions()).any((t) => t.id == txn.id), isFalse);

      await repo.restoreTransaction(txn.id!);
      final active = await repo.readAllTransactions();
      expect(active.any((t) => t.id == txn.id), isTrue);
      expect((await repo.readTrashedTransactions()).any((t) => t.id == txn.id), isFalse);
    });

    test('Permanently purging trashed transaction writes smsId to tombstones and prevents re-importing', () async {
      final txn = await repo.createTransaction(
        TransactionModel(
          amount: 5000,
          description: 'Utility Bill',
          date: DateTime.now(),
          isExpense: true,
          category: 'Bills',
          smsId: 'test_sms_4004',
        ),
      );

      await repo.softDeleteTransaction(txn.id!);
      await repo.permanentlyDeleteTransaction(txn.id!);

      final trashedAfter = await repo.readTrashedTransactions();
      expect(trashedAfter.any((t) => t.id == txn.id), isFalse);

      final existsInTombstone = await repo.smsExists('test_sms_4004');
      expect(existsInTombstone, isTrue, reason: 'Permanently purged transaction smsId must remain in tombstone table');
    });

    test('Emptying trash persists all trashed smsIds into tombstones', () async {
      final txn1 = await repo.createTransaction(
        TransactionModel(
          amount: 100,
          description: 'Item 1',
          date: DateTime.now(),
          smsId: 'tomb_1',
        ),
      );
      final txn2 = await repo.createTransaction(
        TransactionModel(
          amount: 200,
          description: 'Item 2',
          date: DateTime.now(),
          smsId: 'tomb_2',
        ),
      );

      await repo.softDeleteTransaction(txn1.id!);
      await repo.softDeleteTransaction(txn2.id!);

      await repo.emptyTrash();

      expect((await repo.readTrashedTransactions()).isEmpty, isTrue);
      expect(await repo.smsExists('tomb_1'), isTrue);
      expect(await repo.smsExists('tomb_2'), isTrue);
    });
  });

  group('Promotional & OTP SMS Parser Rules Unit Tests', () {
    test('Rejects OTP and verification code messages', () {
      const body = 'Your OTP is 492810 for payment of LKR 1,500. Do not share this secret code.';
      final parsed = SmsParser.parseMessage(
        body: body,
        address: 'HNBAlerts',
        messageId: 101,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: {},
        blockedSenderIds: {},
        customExpenseRules: [],
        customIncomeRules: [],
      );
      expect(parsed, isNull, reason: 'OTP messages must be rejected');
    });

    test('Rejects promotional and discount offer messages without executed transaction keywords', () {
      const promoBody = 'Special OFFER! Get 20% DISCOUNT on spend of LKR 5,000 using your Commercial Bank credit card. Click www.combank.lk/promo to apply now!';
      final parsed = SmsParser.parseMessage(
        body: promoBody,
        address: 'COMBANK',
        messageId: 102,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: {},
        blockedSenderIds: {},
        customExpenseRules: [],
        customIncomeRules: [],
      );
      expect(parsed, isNull, reason: 'Promotional marketing messages must be rejected');
    });

    test('Parses genuine executed debit transaction message correctly', () {
      const debitBody = 'LKR 3,450.00 debited from A/C *1234 on 07/08/2026 at FoodCity Branch. Avl Bal LKR 45,000.00';
      final parsed = SmsParser.parseMessage(
        body: debitBody,
        address: 'COMBANK',
        messageId: 103,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: {},
        blockedSenderIds: {},
        customExpenseRules: [],
        customIncomeRules: [],
      );
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(3450.0));
      expect(parsed.isExpense, isTrue);
    });

    test('Parses genuine executed credit transaction message correctly', () {
      const creditBody = 'Your account has been credited with LKR 25,000.00 on 07/08/2026. Ref: Salary Deposit.';
      final parsed = SmsParser.parseMessage(
        body: creditBody,
        address: 'HNBAlerts',
        messageId: 104,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: {},
        blockedSenderIds: {},
        customExpenseRules: [],
        customIncomeRules: [],
      );
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(25000.0));
      expect(parsed.isExpense, isFalse);
    });
  });
}
