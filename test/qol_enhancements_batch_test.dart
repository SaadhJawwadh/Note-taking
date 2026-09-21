import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/features/finances/data/models/savings_goal_model.dart';
import 'package:note_taking_app/features/settings/data/settings_search_index.dart';
import 'package:note_taking_app/services/sms_service.dart';
import 'package:note_taking_app/services/sms_parser.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:note_taking_app/data/database_helper.dart';
import 'package:note_taking_app/data/transaction_model.dart';
import 'package:note_taking_app/features/finances/data/transaction_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Component 1: Savings Goal Categories & Rich Icon Palette', () {
    test('SavingsGoalModel defaultIcons contains 40+ curated goal icons', () {
      expect(SavingsGoalModel.defaultIcons.length, greaterThanOrEqualTo(40));
      expect(SavingsGoalModel.defaultIcons.contains(Icons.savings_rounded), isTrue);
      expect(SavingsGoalModel.defaultIcons.contains(Icons.flight_takeoff_rounded), isTrue);
      expect(SavingsGoalModel.defaultIcons.contains(Icons.laptop_mac_rounded), isTrue);
      expect(SavingsGoalModel.defaultIcons.contains(Icons.home_rounded), isTrue);
      expect(SavingsGoalModel.defaultIcons.contains(Icons.directions_car_rounded), isTrue);
      expect(SavingsGoalModel.defaultIcons.contains(Icons.school_rounded), isTrue);
    });

    test('SavingsGoalModel.getIcon resolves known icons and falls back safely without error', () {
      final flightIcon = SavingsGoalModel.getIcon(Icons.flight_takeoff_rounded.codePoint);
      expect(flightIcon, equals(Icons.flight_takeoff_rounded));

      // Unknown codePoint falls back gracefully to Icons.savings_rounded
      final fallbackIcon = SavingsGoalModel.getIcon(9999999);
      expect(fallbackIcon, equals(Icons.savings_rounded));
    });
  });

  group('Component 2: Settings Search Index & Section Search', () {
    test('SettingsSearchIndex matches keywords and synonyms across sections', () {
      // Dark mode / OLED keywords match Theme under Appearance
      final themeResults = SettingsSearchIndex.search('dark mode');
      expect(themeResults.any((item) => item.id == 'theme' && item.section == 'Appearance'), isTrue);

      final oledResults = SettingsSearchIndex.search('oled');
      expect(oledResults.any((item) => item.id == 'theme'), isTrue);

      // Biometrics / PIN match App Lock under Security
      final lockResults = SettingsSearchIndex.search('biometrics');
      expect(lockResults.any((item) => item.id == 'app_lock' && item.section == 'Security'), isTrue);

      final pinResults = SettingsSearchIndex.search('pin');
      expect(pinResults.any((item) => item.id == 'app_lock'), isTrue);

      // SAF / Encrypted match Backups under Data
      final safResults = SettingsSearchIndex.search('saf');
      expect(safResults.any((item) => item.id == 'encrypted_backups' && item.section == 'Data'), isTrue);

      // Budget matches Category Budgets under Finances
      final budgetResults = SettingsSearchIndex.search('budget');
      expect(budgetResults.any((item) => item.id == 'category_budgets' && item.section == 'Finances'), isTrue);

      // Section filtering works accurately
      final financeItems = SettingsSearchIndex.search('sms', section: 'Finances');
      expect(financeItems.isNotEmpty, isTrue);
      expect(financeItems.every((item) => item.section == 'Finances'), isTrue);
    });
  });

  group('Component 3: SMS Sync Timestamp Normalization & Feedback', () {
    test('SmsParser.resolveMessageDate correctly handles 10-digit seconds and 13-digit milliseconds', () {
      final now = DateTime.now();
      final msEpoch = now.millisecondsSinceEpoch;
      final secEpoch = msEpoch ~/ 1000;

      final fromMs = SmsParser.resolveMessageDate(msEpoch);
      final fromSec = SmsParser.resolveMessageDate(secEpoch);

      expect(fromMs.year, equals(now.year));
      expect(fromMs.month, equals(now.month));
      expect(fromMs.day, equals(now.day));

      expect(fromSec.year, equals(now.year));
      expect(fromSec.month, equals(now.month));
      expect(fromSec.day, equals(now.day));
    });

    test('SmsSyncProgress preserves alreadyImported count accurately', () {
      const progress = SmsSyncProgress(
        isSyncing: false,
        found: 3,
        alreadyImported: 5,
        message: 'Imported 3 new transactions (5 up-to-date)',
      );

      expect(progress.isSyncing, isFalse);
      expect(progress.found, equals(3));
      expect(progress.alreadyImported, equals(5));
      expect(progress.message, contains('5 up-to-date'));
    });
  });

  group('Component 4: Atomic Bulk Operations in TransactionRepository', () {
    late Database db;
    late TransactionRepository repo;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

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

    test('bulkDeleteTransactions soft-deletes multiple transactions atomically', () async {
      final t1 = await repo.createTransaction(
        TransactionModel(amount: 100, description: 'Item 1', date: DateTime.now(), isExpense: true, category: 'Food'),
      );
      final t2 = await repo.createTransaction(
        TransactionModel(amount: 200, description: 'Item 2', date: DateTime.now(), isExpense: true, category: 'Food'),
      );
      final t3 = await repo.createTransaction(
        TransactionModel(amount: 300, description: 'Item 3', date: DateTime.now(), isExpense: true, category: 'Food'),
      );

      final deleted = await repo.bulkDeleteTransactions([t1.id!, t2.id!]);
      expect(deleted, equals(2));

      final active = await repo.readAllTransactions();
      expect(active.length, equals(1));
      expect(active.first.id, equals(t3.id));

      final trashed = await repo.readTrashedTransactions();
      expect(trashed.length, equals(2));
      expect(trashed.any((t) => t.id == t1.id), isTrue);
      expect(trashed.any((t) => t.id == t2.id), isTrue);
    });

    test('bulkRestoreTransactions restores soft-deleted transactions atomically', () async {
      final t1 = await repo.createTransaction(
        TransactionModel(amount: 100, description: 'Item 1', date: DateTime.now(), isExpense: true, category: 'Food'),
      );
      final t2 = await repo.createTransaction(
        TransactionModel(amount: 200, description: 'Item 2', date: DateTime.now(), isExpense: true, category: 'Food'),
      );

      await repo.bulkDeleteTransactions([t1.id!, t2.id!]);
      expect((await repo.readAllTransactions()).isEmpty, isTrue);

      final restored = await repo.bulkRestoreTransactions([t1.id!, t2.id!]);
      expect(restored, equals(2));

      final active = await repo.readAllTransactions();
      expect(active.length, equals(2));
    });

    test('bulkUpdateCategory updates category across multiple transactions', () async {
      final t1 = await repo.createTransaction(
        TransactionModel(amount: 100, description: 'Item 1', date: DateTime.now(), isExpense: true, category: 'Uncategorized'),
      );
      final t2 = await repo.createTransaction(
        TransactionModel(amount: 200, description: 'Item 2', date: DateTime.now(), isExpense: true, category: 'Shopping'),
      );

      final updated = await repo.bulkUpdateCategory([t1.id!, t2.id!], 'Dining Out');
      expect(updated, equals(2));

      final read1 = await repo.readTransaction(t1.id!);
      final read2 = await repo.readTransaction(t2.id!);
      expect(read1?.category, equals('Dining Out'));
      expect(read2?.category, equals('Dining Out'));
    });

    test('bulkUpdateAccount reassigns account across multiple transactions', () async {
      final t1 = await repo.createTransaction(
        TransactionModel(amount: 500, description: 'Deposit', date: DateTime.now(), isExpense: false, category: 'Income', account: 'daily'),
      );
      final t2 = await repo.createTransaction(
        TransactionModel(amount: 600, description: 'Transfer', date: DateTime.now(), isExpense: false, category: 'Income', account: 'daily'),
      );

      final updated = await repo.bulkUpdateAccount([t1.id!, t2.id!], 'savings');
      expect(updated, equals(2));

      final read1 = await repo.readTransaction(t1.id!);
      final read2 = await repo.readTransaction(t2.id!);
      expect(read1?.account, equals('savings'));
      expect(read2?.account, equals('savings'));
    });
  });
}

