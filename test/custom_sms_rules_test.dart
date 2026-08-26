import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note_taking_app/data/custom_sms_rule.dart';
import 'package:note_taking_app/features/settings/providers/settings_provider.dart';
import 'package:note_taking_app/services/sms_parser.dart';
import 'package:note_taking_app/data/category_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomSmsRule Model & Serialization Tests', () {
    test('Serializes to and from Map correctly', () {
      final now = DateTime.now();
      final rule = CustomSmsRule(
        id: 'rule_1',
        keyword: 'Digital-Transfer',
        type: RuleTransactionType.transfer,
        category: 'Transfer',
        customDescription: 'ComBank Internal Transfer',
        bypassOtpFilter: true,
        isEnabled: true,
        createdAt: now,
      );

      final map = rule.toMap();
      final fromMap = CustomSmsRule.fromMap(map);

      expect(fromMap.id, equals('rule_1'));
      expect(fromMap.keyword, equals('Digital-Transfer'));
      expect(fromMap.type, equals(RuleTransactionType.transfer));
      expect(fromMap.category, equals('Transfer'));
      expect(fromMap.customDescription, equals('ComBank Internal Transfer'));
      expect(fromMap.bypassOtpFilter, isTrue);
      expect(fromMap.isEnabled, isTrue);
    });

    test('Serializes to and from JSON correctly', () {
      final rule = CustomSmsRule(
        id: 'rule_2',
        keyword: 'Salary Deposit',
        type: RuleTransactionType.income,
        category: 'Salary',
        customDescription: 'Monthly Company Salary',
        bypassOtpFilter: false,
        isEnabled: false,
        createdAt: DateTime.now(),
      );

      final jsonStr = rule.toJson();
      final fromJson = CustomSmsRule.fromJson(jsonStr);

      expect(fromJson.id, equals('rule_2'));
      expect(fromJson.keyword, equals('Salary Deposit'));
      expect(fromJson.type, equals(RuleTransactionType.income));
      expect(fromJson.isEnabled, isFalse);
    });
  });

  group('SettingsProvider Custom Rules State & Migration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads and saves custom SMS rules in SettingsProvider', () async {
      final provider = SettingsProvider();
      await provider.loadSettings();

      expect(provider.customSmsRules, isEmpty);

      final rule = CustomSmsRule(
        id: 'rule_test_1',
        keyword: 'Amana Profit',
        type: RuleTransactionType.income,
        category: 'Investments',
        createdAt: DateTime.now(),
      );

      await provider.saveCustomSmsRule(rule);
      expect(provider.customSmsRules.length, equals(1));
      expect(provider.customSmsRules.first.keyword, equals('Amana Profit'));
      expect(provider.activeCustomSmsRules.length, equals(1));

      // Toggle rule
      await provider.toggleCustomSmsRule('rule_test_1');
      expect(provider.customSmsRules.first.isEnabled, isFalse);
      expect(provider.activeCustomSmsRules, isEmpty);

      // Delete rule
      await provider.deleteCustomSmsRule('rule_test_1');
      expect(provider.customSmsRules, isEmpty);

      // Restore rule
      await provider.restoreCustomSmsRule(rule);
      expect(provider.customSmsRules.length, equals(1));
    });

    test('Automatically migrates legacy string lists on initial load', () async {
      SharedPreferences.setMockInitialValues({
        'customExpenseRules': ['Paid Keells', 'Uber Ride'],
        'customIncomeRules': ['Salary Deposit'],
      });

      final provider = SettingsProvider();
      await provider.loadSettings();

      expect(provider.customSmsRules.length, equals(3));
      expect(provider.customSmsRules.any((r) => r.keyword == 'Paid Keells' && r.type == RuleTransactionType.expense), isTrue);
      expect(provider.customSmsRules.any((r) => r.keyword == 'Uber Ride' && r.type == RuleTransactionType.expense), isTrue);
      expect(provider.customSmsRules.any((r) => r.keyword == 'Salary Deposit' && r.type == RuleTransactionType.income), isTrue);
    });
  });

  group('SmsParser Custom Rule Integration & ComBank Transfer Tests', () {
    const combankTransferSms =
        'ComBank Digital-Transfer within ComBank LKR 10,000.00 attempted. Please use code 968352 to approve. Do NOT share this number with anyone. PbgqGoDg8jk';

    test('Rejects ComBank transfer approval SMS by default without taught rule', () {
      final parsed = SmsParser.parseMessage(
        body: combankTransferSms,
        address: 'COMBANK',
        messageId: 100,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: {},
        blockedSenderIds: {},
        customExpenseRules: [],
        customIncomeRules: [],
        customSmsRules: [],
      );

      expect(parsed, isNull, reason: 'Must be rejected by default because it contains approval code');
    });

    test('Successfully parses ComBank transfer approval SMS when user teaches a custom rule with OTP bypass', () {
      final taughtRule = CustomSmsRule(
        id: 'rule_combank',
        keyword: 'Digital-Transfer',
        type: RuleTransactionType.expense,
        category: CategoryConstants.transfer,
        customDescription: 'ComBank Internal Transfer',
        bypassOtpFilter: true,
        isEnabled: true,
        createdAt: DateTime.now(),
      );

      final parsed = SmsParser.parseMessage(
        body: combankTransferSms,
        address: 'COMBANK',
        messageId: 101,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: {},
        blockedSenderIds: {},
        customExpenseRules: [],
        customIncomeRules: [],
        customSmsRules: [taughtRule],
        preferredCurrency: 'LKR',
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(10000.0));
      expect(parsed.isExpense, isTrue);
      expect(parsed.description, equals('ComBank Internal Transfer'));
      expect(parsed.category, equals(CategoryConstants.transfer));
    });

    test('Does not parse ComBank approval SMS if the taught rule is disabled', () {
      final disabledRule = CustomSmsRule(
        id: 'rule_combank_disabled',
        keyword: 'Digital-Transfer',
        type: RuleTransactionType.expense,
        bypassOtpFilter: true,
        isEnabled: false,
        createdAt: DateTime.now(),
      );

      final parsed = SmsParser.parseMessage(
        body: combankTransferSms,
        address: 'COMBANK',
        messageId: 102,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: {},
        blockedSenderIds: {},
        customExpenseRules: [],
        customIncomeRules: [],
        customSmsRules: [disabledRule],
      );

      expect(parsed, isNull);
    });

    test('Card payment OTP messages are still safely rejected even if transfer rule exists', () {
      const cardOtpSms = 'Your OTP for payment of LKR 4,500.00 at Keells Super is 829103. Do not share.';
      final transferRule = CustomSmsRule(
        id: 'rule_combank',
        keyword: 'Digital-Transfer',
        type: RuleTransactionType.expense,
        bypassOtpFilter: true,
        createdAt: DateTime.now(),
      );

      final parsed = SmsParser.parseMessage(
        body: cardOtpSms,
        address: 'COMBANK',
        messageId: 103,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: {},
        blockedSenderIds: {},
        customExpenseRules: [],
        customIncomeRules: [],
        customSmsRules: [transferRule],
      );

      expect(parsed, isNull, reason: 'Card OTP must still be safely rejected');
    });

    test('Custom Income rule correctly overrides standard parsing and applies custom category', () {
      const dividendSms = 'Special settlement of LKR 45,000.00 credited to account *9988 from Unit Trust.';
      final incomeRule = CustomSmsRule(
        id: 'rule_dividend',
        keyword: 'Unit Trust',
        type: RuleTransactionType.income,
        category: 'Investments',
        customDescription: 'Unit Trust Dividend',
        createdAt: DateTime.now(),
      );

      final parsed = SmsParser.parseMessage(
        body: dividendSms,
        address: 'ALERT',
        messageId: 104,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: {},
        blockedSenderIds: {},
        customExpenseRules: [],
        customIncomeRules: [],
        customSmsRules: [incomeRule],
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(45000.0));
      expect(parsed.isExpense, isFalse);
      expect(parsed.description, equals('Unit Trust Dividend'));
      expect(parsed.category, equals('Investments'));
    });
  });
}
