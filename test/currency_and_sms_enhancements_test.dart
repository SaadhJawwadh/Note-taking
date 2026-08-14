import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/utils/app_constants.dart';
import 'package:note_taking_app/services/sms_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Currency & SMS Enhancements Tests', () {
    test('AppConstants provides accurate symbols and names for curated currencies', () {
      expect(AppConstants.curatedCurrencies.length, greaterThanOrEqualTo(14));

      final lkr = AppConstants.getCurrencyInfo('LKR');
      expect(lkr.symbol, equals('Rs.'));
      expect(lkr.name, equals('Sri Lankan Rupee'));

      final inr = AppConstants.getCurrencyInfo('INR');
      expect(inr.symbol, equals('₹'));
      expect(inr.name, equals('Indian Rupee'));

      final usd = AppConstants.getCurrencyInfo('USD');
      expect(usd.symbol, equals('\$'));

      final eur = AppConstants.getCurrencyInfo('EUR');
      expect(eur.symbol, equals('€'));

      final gbp = AppConstants.getCurrencyInfo('GBP');
      expect(gbp.symbol, equals('£'));

      final aed = AppConstants.getCurrencyInfo('AED');
      expect(aed.symbol, equals('د.إ'));

      // Custom currency fallback
      final custom = AppConstants.getCurrencyInfo('BRL');
      expect(custom.code, equals('BRL'));
      expect(custom.symbol, equals('BRL'));
    });

    test('SmsParser extracts amounts prioritizing preferred currency', () {
      const body = 'Acct 987654 debited LKR 3,450.50. Ref 112233. Avl Bal LKR 90,000.00';
      final parsed = SmsParser.parseMessage(
        body: body,
        address: 'COMBANK',
        messageId: 1,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: const {},
        blockedSenderIds: const {},
        customExpenseRules: const [],
        customIncomeRules: const [],
        preferredCurrency: 'LKR',
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(3450.50));
      expect(parsed.isExpense, isTrue);
    });

    test('SmsParser extracts quoted merchant names accurately', () {
      const body = 'Paid LKR 1,800.00 at "Keells Super" on 12/05/2026';
      final parsed = SmsParser.parseMessage(
        body: body,
        address: 'HNB',
        messageId: 2,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: const {},
        blockedSenderIds: const {},
        customExpenseRules: const [],
        customIncomeRules: const [],
        preferredCurrency: 'LKR',
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(1800.00));
      expect(parsed.description, contains('Keells Super'));
    });

    test('SmsParser extracts POS merchants with code prefixes cleaned', () {
      const body = 'Debited Rs. 750.00 at POS 54321 SPAR Supermarket ref 98765';
      final parsed = SmsParser.parseMessage(
        body: body,
        address: 'SAMPATH',
        messageId: 3,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: const {},
        blockedSenderIds: const {},
        customExpenseRules: const [],
        customIncomeRules: const [],
        preferredCurrency: 'LKR',
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(750.00));
      expect(parsed.description, contains('Spar Supermarket'));
    });

    test('SmsParser extracts UPI / VPA handles cleanly', () {
      const body = 'Paid INR 250.00 to chai.point@okaxis on 10-06-2026';
      final parsed = SmsParser.parseMessage(
        body: body,
        address: 'HDFC',
        messageId: 4,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: const {'hdfc'},
        blockedSenderIds: const {},
        customExpenseRules: const ['Paid'],
        customIncomeRules: const [],
        preferredCurrency: 'INR',
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(250.00));
      expect(parsed.description, contains('Chai Point'));
    });

    test('SmsParser parses Cardholder purchase in Sandbox', () {
      const body = 'Dear Cardholder, Purchase at CARGILLS FOOD CITY- MC COLOMBO 04 LK for LKR 795.00';
      final parsed = SmsParser.parseMessage(
        body: body,
        address: 'BANK_SMS',
        messageId: 5,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: const {},
        blockedSenderIds: const {},
        customExpenseRules: const [],
        customIncomeRules: const [],
        preferredCurrency: 'LKR',
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(795.00));
      expect(parsed.isExpense, isTrue);
      expect(parsed.description, contains('Cargills Food City'));
    });
  });
}
