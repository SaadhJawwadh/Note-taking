import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:note_taking_app/data/database_helper.dart';
import 'package:note_taking_app/data/recurring_rule_model.dart';
import 'package:note_taking_app/data/repositories/recurring_rule_repository.dart';
import 'package:note_taking_app/features/finances/data/transaction_repository.dart';
import 'package:note_taking_app/data/transaction_model.dart';
import 'package:note_taking_app/features/finances/services/financial_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 3: Financial Feature Enhancements Tests', () {
    late Database testDb;

    setUp(() async {
      testDb = await openDatabase(
        inMemoryDatabasePath,
        version: 19,
        onCreate: (db, version) async {
          await DatabaseHelper.instance.createTestDatabase(db);
        },
      );
      DatabaseHelper.setMockDatabase(testDb);
    });

    tearDown(() async {
      await testDb.close();
      DatabaseHelper.setMockDatabase(null);
    });

    test('RecurringRule frequency advance calculations', () {
      final start = DateTime(2026, 1, 31);

      // Daily
      final dailyRule = RecurringRule(
        id: 'r_daily',
        description: 'Coffee',
        amount: 150,
        category: 'Food',
        isExpense: true,
        frequency: RecurringFrequency.daily,
        nextDue: start,
      );
      expect(dailyRule.advance(start), DateTime(2026, 2, 1));

      // Weekly
      final weeklyAdv = RecurringRule(
        id: 'r_weekly',
        description: 'Gym class',
        amount: 500,
        category: 'Health',
        isExpense: true,
        frequency: RecurringFrequency.weekly,
        nextDue: start,
      ).advance(start);
      expect(weeklyAdv, DateTime(2026, 2, 7));

      // Monthly with end-of-month clamp (Jan 31 -> Feb 28 in non-leap year)
      final monthlyRule = RecurringRule(
        id: 'r_monthly',
        description: 'Rent',
        amount: 25000,
        category: 'Housing',
        isExpense: true,
        frequency: RecurringFrequency.monthly,
        nextDue: start,
      );
      final monthlyAdv = monthlyRule.advance(start);
      expect(monthlyAdv.month, 2);
      expect(monthlyAdv.day, 28);
    });

    test('RecurringRuleRepository.materializeDueRules creates transactions and advances nextDue', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 3));

      final dueRule = RecurringRule(
        id: 'rule_sub_1',
        description: 'Cloud Storage Subscription',
        amount: 299.0,
        category: 'Bills',
        isExpense: true,
        frequency: RecurringFrequency.daily,
        nextDue: pastDate,
      );

      await RecurringRuleRepository.instance.createRule(dueRule);

      // Materialize due rules
      final createdCount = await RecurringRuleRepository.instance.materializeDueRules();
      expect(createdCount, greaterThan(0));

      final allTx = await TransactionRepository.instance.readAllTransactions();
      expect(allTx.any((t) => t.description == 'Cloud Storage Subscription'), isTrue);

      final rules = await RecurringRuleRepository.instance.readAllRules();
      expect(rules.first.nextDue.isAfter(pastDate), isTrue);
    });

    test('FinancialExportService.generateCsv generates valid RFC 4180 CSV with escaped fields', () {
      final transactions = [
        TransactionModel(
          id: 1,
          amount: 450.50,
          description: 'Groceries, Supermarket & "Fresh" Items',
          date: DateTime(2026, 8, 15, 14, 30),
          isExpense: true,
          category: 'Groceries',
          smsId: 'SMS_9988',
        ),
        TransactionModel(
          id: 2,
          amount: 50000.0,
          description: 'Monthly Salary',
          date: DateTime(2026, 8, 1, 9, 0),
          isExpense: false,
          category: 'Income',
          smsId: null,
        ),
      ];

      final csv = FinancialExportService.generateCsv(transactions, currency: 'Rs.');
      final lines = csv.trim().split('\n');

      expect(lines.first, 'Date,Time,Description,Category,Account,Type,Amount,Currency,SMS_ID');
      expect(lines.length, 3);

      // Line 1 checks quoted escaped comma and quote
      expect(lines[1], contains('"Groceries, Supermarket & ""Fresh"" Items"'));
      expect(lines[1], contains('Expense'));
      expect(lines[1], contains('450.50'));
      expect(lines[1], contains('SMS_9988'));

      // Line 2 checks income
      expect(lines[2], contains('Monthly Salary'));
      expect(lines[2], contains('Income'));
      expect(lines[2], contains('50000.00'));
    });
  });
}
