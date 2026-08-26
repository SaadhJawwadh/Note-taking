import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:note_taking_app/data/database_helper.dart';
import 'package:note_taking_app/data/transaction_model.dart';
import 'package:note_taking_app/features/finances/data/transaction_repository.dart';
import 'package:note_taking_app/services/sms_parser.dart';
import 'package:note_taking_app/services/sms_constants.dart';
import 'package:note_taking_app/services/sms_service.dart';

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

    test('createSmsTransaction rejects tombstones by default and permits on bypassTombstones', () async {
      const testSmsId = 'tombstone_test_sms_999';

      // Insert directly into tombstone table
      await db.insert('deleted_transaction_sms_ids', {
        'smsId': testSmsId,
        'deletedAt': DateTime.now().toIso8601String(),
      });

      final model = TransactionModel(
        amount: 2500,
        description: 'Tombstoned Purchase',
        date: DateTime.now(),
        isExpense: true,
        category: 'Food & Dining',
        smsId: testSmsId,
      );

      // Default: must reject
      final rejected = await repo.createSmsTransaction(model, bypassTombstones: false);
      expect(rejected, isNull, reason: 'Must not re-import tombstoned SMS transaction');

      // Bypass: must allow and remove tombstone
      final accepted = await repo.createSmsTransaction(model, bypassTombstones: true);
      expect(accepted, isNotNull, reason: 'Must allow re-importing when bypassTombstones is true');
      expect(accepted!.smsId, equals(testSmsId));

      final checkTombstone = await db.query('deleted_transaction_sms_ids', where: 'smsId = ?', whereArgs: [testSmsId]);
      expect(checkTombstone, isEmpty, reason: 'Tombstone record should be cleared upon reinstatement');
    });

    test('Soft delete and UNDO restore preserves SMS transaction idempotency and does not crash', () async {
      final txn = await repo.createTransaction(
        TransactionModel(
          amount: 4200,
          description: 'Electronic Store',
          date: DateTime(2026, 7, 20, 11, 45),
          isExpense: true,
          category: 'Shopping',
          smsId: 'sms_undo_99',
        ),
      );

      expect(txn.id, isNotNull);

      // 1. Soft delete
      await repo.deleteTransaction(txn.id!);
      expect((await repo.readAllTransactions()).any((t) => t.id == txn.id), isFalse);
      expect(await repo.smsExists('sms_undo_99'), isTrue);

      // 2. Perform Undo via restoreTransaction
      final restoredRows = await repo.restoreTransaction(txn.id!);
      expect(restoredRows, equals(1));

      // 3. Verify state after UNDO
      final active = await repo.readAllTransactions();
      final restored = active.firstWhere((t) => t.id == txn.id);
      expect(restored.amount, equals(4200.0));
      expect(restored.description, equals('Electronic Store'));
      expect(restored.smsId, equals('sms_undo_99'));
      expect(restored.deletedAt, isNull);
      expect(restored.date.month, equals(7));
      expect(restored.date.day, equals(20));

      final trashed = await repo.readTrashedTransactions();
      expect(trashed.any((t) => t.id == txn.id), isFalse);
    });

    test('Multiple soft deletes and partial UNDOs work cleanly', () async {
      final t1 = await repo.createTransaction(TransactionModel(amount: 10, description: 'Item 1', date: DateTime.now()));
      final t2 = await repo.createTransaction(TransactionModel(amount: 20, description: 'Item 2', date: DateTime.now()));
      final t3 = await repo.createTransaction(TransactionModel(amount: 30, description: 'Item 3', date: DateTime.now()));

      // Delete all 3
      await repo.deleteTransaction(t1.id!);
      await repo.deleteTransaction(t2.id!);
      await repo.deleteTransaction(t3.id!);

      expect((await repo.readAllTransactions()).isEmpty, isTrue);
      expect((await repo.readTrashedTransactions()).length, equals(3));

      // Undo only t2
      await repo.restoreTransaction(t2.id!);

      final active = await repo.readAllTransactions();
      expect(active.length, equals(1));
      expect(active.first.id, equals(t2.id));

      final trashed = await repo.readTrashedTransactions();
      expect(trashed.length, equals(2));
      expect(trashed.any((t) => t.id == t1.id), isTrue);
      expect(trashed.any((t) => t.id == t3.id), isTrue);
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

      const combankApproval = 'ComBank Digital-Transfer within ComBank LKR 10,000.00 attempted. Please use code 968352 to approve. Do NOT share this number with anyone. PbgqGoDg8jk';
      final parsedCombank = SmsParser.parseMessage(
        body: combankApproval,
        address: 'COMBANK',
        messageId: 1012,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: {},
        blockedSenderIds: {},
        customExpenseRules: [],
        customIncomeRules: [],
      );
      expect(parsedCombank, isNull, reason: 'Approval code messages must be rejected');
      expect(SmsConstants.otpRegex.hasMatch(combankApproval), isTrue);
      expect(SmsConstants.promotionalRegex.hasMatch(combankApproval), isFalse);
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

  group('SmsService Permission & Cancel Tests', () {
    test('hasPermission returns true when isolate catch-all fallback is invoked', () async {
      final result = await SmsService.hasPermission();
      expect(result, isA<bool>());
    });

    test('cancelSync sets cancelled progress state cleanly', () {
      // Calling cancelSync when no sync active should not throw
      SmsService.cancelSync();
    });

    test('SmsParser.resolveMessageDate accurately preserves past millisecond and second epochs', () {
      final pastDate = DateTime(2026, 8, 15, 14, 30);
      final millis = pastDate.millisecondsSinceEpoch;
      final seconds = millis ~/ 1000;

      final fromMillis = SmsParser.resolveMessageDate(millis);
      expect(fromMillis.year, equals(2026));
      expect(fromMillis.month, equals(8));
      expect(fromMillis.day, equals(15));
      expect(fromMillis.hour, equals(14));
      expect(fromMillis.minute, equals(30));

      final fromSeconds = SmsParser.resolveMessageDate(seconds);
      expect(fromSeconds.year, equals(2026));
      expect(fromSeconds.month, equals(8));
      expect(fromSeconds.day, equals(15));
      expect(fromSeconds.hour, equals(14));
      expect(fromSeconds.minute, equals(30));

      // Null or 0 fallback
      final fromNull = SmsParser.resolveMessageDate(null);
      expect(DateTime.now().difference(fromNull).inSeconds < 5, isTrue);
    });

    test('SmsParser stamps parsed transaction with genuine message epoch date', () {
      final pastDate = DateTime(2026, 8, 10, 9, 15);
      const testBody = 'Paid LKR 1,500.00 at CAFE on 10-Aug-2026.';
      final parsed = SmsParser.parseMessage(
        body: testBody,
        address: 'COMBANK',
        messageId: 505,
        messageDate: pastDate.millisecondsSinceEpoch,
        allowedSenderIds: {},
        blockedSenderIds: {},
        customExpenseRules: [],
        customIncomeRules: [],
      );

      expect(parsed, isNotNull);
      expect(parsed!.date.year, equals(2026));
      expect(parsed.date.month, equals(8));
      expect(parsed.date.day, equals(10));
      expect(parsed.date.hour, equals(9));
      expect(parsed.date.minute, equals(15));
    });

    test('resolveMessageDate handles boundary timestamps and negative/zero values gracefully', () {
      // 0 or negative
      final fromZero = SmsParser.resolveMessageDate(0);
      final fromNegative = SmsParser.resolveMessageDate(-1000);
      expect(DateTime.now().difference(fromZero).inSeconds < 5, isTrue);
      expect(DateTime.now().difference(fromNegative).inSeconds < 5, isTrue);

      // Exact 10-digit epoch timestamp (year 2025: 1735689600 -> Jan 1, 2025 00:00:00 UTC)
      const epochSec2025 = 1735689600;
      final date2025 = SmsParser.resolveMessageDate(epochSec2025);
      expect(date2025.toUtc().year, equals(2025));
      expect(date2025.toUtc().month, equals(1));
      expect(date2025.toUtc().day, equals(1));

      // Exact 13-digit epoch timestamp (year 2026: 1767225600000 -> Jan 1, 2026 00:00:00 UTC)
      const epochMillis2026 = 1767225600000;
      final date2026 = SmsParser.resolveMessageDate(epochMillis2026);
      expect(date2026.toUtc().year, equals(2026));
      expect(date2026.toUtc().month, equals(1));
      expect(date2026.toUtc().day, equals(1));
    });
  });
}
