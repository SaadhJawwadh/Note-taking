import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:note_taking_app/services/notification_service.dart';
import 'package:note_taking_app/data/recurring_rule_model.dart';
import 'package:note_taking_app/data/transaction_model.dart';
import 'package:note_taking_app/features/finances/services/financial_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Editor & SMS & Auto-Backup QoL Tests', () {
    test('Quill header attribute extraction maps to correct heading levels', () {
      final doc = Document();
      final controller = QuillController.basic()..document = doc;

      // Default should have no header (Body)
      var style = controller.getSelectionStyle();
      expect(style.attributes[Attribute.header.key], isNull);

      // Format as H1
      controller.formatSelection(Attribute.h1);
      style = controller.getSelectionStyle();
      expect(style.attributes[Attribute.header.key], equals(Attribute.h1));

      // Format as H2
      controller.formatSelection(Attribute.h2);
      style = controller.getSelectionStyle();
      expect(style.attributes[Attribute.header.key], equals(Attribute.h2));

      // Format as H3
      controller.formatSelection(Attribute.h3);
      style = controller.getSelectionStyle();
      expect(style.attributes[Attribute.header.key], equals(Attribute.h3));

      // Format back to Body
      controller.formatSelection(const Attribute('header', AttributeScope.block, null));
      style = controller.getSelectionStyle();
      expect(style.attributes[Attribute.header.key], isNull);
    });

    test('showBackupNotification runs without unhandled exception', () async {
      await NotificationService.showBackupNotification(
        title: '📦 Auto-Backup Complete',
        body: 'Data safely backed up at 10:30 PM.',
      );
      // Completes cleanly
      expect(true, isTrue);
    });

    test('RecurringRule frequency advances correctly across cycle frequencies', () {
      final baseDate = DateTime(2026, 1, 15);
      
      final dailyRule = RecurringRule(
        id: 'r_daily',
        description: 'Gym',
        amount: 50.0,
        category: 'Health',
        isExpense: true,
        frequency: RecurringFrequency.daily,
        nextDue: baseDate,
      );
      expect(dailyRule.advance(baseDate), DateTime(2026, 1, 16));

      final weeklyRule = RecurringRule(
        id: 'r_weekly',
        description: 'Groceries',
        amount: 200.0,
        category: 'Food',
        isExpense: true,
        frequency: RecurringFrequency.weekly,
        nextDue: baseDate,
      );
      expect(weeklyRule.advance(baseDate), DateTime(2026, 1, 22));

      final monthlyRule = RecurringRule(
        id: 'r_monthly',
        description: 'Netflix',
        amount: 15.99,
        category: 'Subscriptions',
        isExpense: true,
        frequency: RecurringFrequency.monthly,
        nextDue: baseDate,
      );
      expect(monthlyRule.advance(baseDate), DateTime(2026, 2, 15));
    });

    test('FinancialExportService builds comprehensive AI spending analysis prompt', () {
      final prompt = FinancialExportService.buildAiAnalysisPrompt(
        transactionCount: 42,
        currency: 'LKR',
      );

      expect(prompt, contains('AI Financial Health & Spending Habits Analysis Prompt'));
      expect(prompt, contains('42 records in LKR'));
      expect(prompt, contains('Executive Financial Overview'));
      expect(prompt, contains('50/30/20 Rule'));
      expect(prompt, contains('Recurring Subscriptions'));
      expect(prompt, contains('Top Merchant Drains'));
    });

    test('FinancialExportService generateCsv formats RFC 4180 CSV with optional AI header', () {
      final txList = [
        TransactionModel(
          id: 1,
          amount: 2500.0,
          description: 'Keells Super, Colombo',
          date: DateTime(2026, 8, 20, 14, 30),
          isExpense: true,
          category: 'Food & Dining',
          smsId: 'sms_101',
        ),
        TransactionModel(
          id: 2,
          amount: 150000.0,
          description: 'Monthly Salary "August"',
          date: DateTime(2026, 8, 25, 9, 0),
          isExpense: false,
          category: 'Salary',
        ),
      ];

      // Standard CSV without preamble
      final standardCsv = FinancialExportService.generateCsv(txList, currency: 'Rs.', includeAiPreamble: false);
      expect(standardCsv.startsWith('Date,Time,Description,Category,Account,Type,Amount,Currency,SMS_ID'), isTrue);
      expect(standardCsv, contains('"Keells Super, Colombo"'));
      expect(standardCsv, contains('"Monthly Salary ""August"""'));
      expect(standardCsv, contains('2500.00'));
      expect(standardCsv, contains('Expense'));
      expect(standardCsv, contains('Income'));
      expect(standardCsv, contains('Daily'));

      // AI-assisted CSV with preamble
      final aiCsv = FinancialExportService.generateCsv(txList, currency: 'Rs.', includeAiPreamble: true);
      expect(aiCsv.startsWith('# Everything App Financial Ledger Export'), isTrue);
      expect(aiCsv, contains('# Currency: Rs. | Total Records: 2'));
      expect(aiCsv, contains('Date,Time,Description,Category,Account,Type,Amount,Currency,SMS_ID'));
    });

    test('TransactionModel defaults to daily operating account and supports savings vault', () {
      final defaultTx = TransactionModel(
        amount: 500.0,
        description: 'Coffee',
        date: DateTime.now(),
      );
      expect(defaultTx.account, equals(AccountType.daily));

      final savingsTx = TransactionModel(
        amount: 25000.0,
        description: 'Emergency Fund Deposit',
        date: DateTime.now(),
        isExpense: false,
        account: AccountType.savings,
      );
      expect(savingsTx.account, equals(AccountType.savings));

      final json = savingsTx.toJson();
      expect(json[TransactionFields.account], equals('savings'));

      final restored = TransactionModel.fromJson(json);
      expect(restored.account, equals(AccountType.savings));
    });
  });
}
