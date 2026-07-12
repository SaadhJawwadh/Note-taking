import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/services/sms_parser.dart';
import 'package:another_telephony/telephony.dart';

void main() {
  group('SMS Parser Custom Rules Tests', () {
    test('Parses custom expense rules correctly', () {
      final smsMap = {
        'address': 'KOKO_PAY',
        'body': 'You have successfully paid LKR 1,500.00 to merchant Uber.',
        'date': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      final sms = SmsMessage.fromMap(smsMap, [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE]);

      // Parse without rules (fails to determine type because KOKO_PAY / successfully paid might not match built-in bank filters if sender not recognized)
      final tNoRules = SmsParser.parseMessage(
        body: sms.body ?? '',
        address: sms.address ?? '',
        messageId: sms.id,
        messageDate: sms.date,
        allowedSenderIds: {'koko_pay'}, // allow the sender
        blockedSenderIds: {},
        customExpenseRules: [],
        customIncomeRules: [],
      );
      expect(tNoRules, isNull);
      
      // Parse with custom rules
      final tWithRules = SmsParser.parseMessage(
        body: sms.body ?? '',
        address: sms.address ?? '',
        messageId: sms.id,
        messageDate: sms.date,
        allowedSenderIds: {'koko_pay'},
        blockedSenderIds: {},
        customExpenseRules: ['successfully paid'],
        customIncomeRules: [],
      );

      expect(tWithRules, isNotNull);
      expect(tWithRules!.isExpense, isTrue);
      expect(tWithRules.amount, 1500.0);
    });

    test('Parses custom income rules correctly', () {
      final smsMap = {
        'address': 'RANDOM_SENDER',
        'body': 'Salary credit of Rs 95,000.00 received in your account.',
        'date': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      final sms = SmsMessage.fromMap(smsMap, [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE]);

      final tWithRules = SmsParser.parseMessage(
        body: sms.body ?? '',
        address: sms.address ?? '',
        messageId: sms.id,
        messageDate: sms.date,
        allowedSenderIds: {'random_sender'},
        blockedSenderIds: {},
        customExpenseRules: [],
        customIncomeRules: ['Salary credit'],
      );

      expect(tWithRules, isNotNull);
      expect(tWithRules!.isExpense, isFalse); // Should be income
      expect(tWithRules.amount, 95000.0);
    });

    test('isPotentiallyRelevant identifies transactional and non-transactional messages correctly', () {
      final allowed = <String>{'koko_pay'};
      final blocked = <String>{'spam_sender'};

      // 1. Bank sender (always relevant)
      expect(SmsParser.isPotentiallyRelevant(
        body: 'Your account has been debited Rs. 500.00',
        address: 'COMBANK',
        allowedSenderIds: allowed,
        blockedSenderIds: blocked,
      ), isTrue);

      // 2. Allowed sender + transaction words + amount (relevant)
      expect(SmsParser.isPotentiallyRelevant(
        body: 'LKR 1,500.00 paid to Uber',
        address: 'KOKO_PAY',
        allowedSenderIds: allowed,
        blockedSenderIds: blocked,
      ), isTrue);

      // 3. Non-transactional message (no amount, e.g. OTP) (not relevant)
      expect(SmsParser.isPotentiallyRelevant(
        body: 'Your OTP is 123456. Do not share.',
        address: 'KOKO_PAY',
        allowedSenderIds: allowed,
        blockedSenderIds: blocked,
      ), isFalse);

      // 4. Blocked sender (always not relevant)
      expect(SmsParser.isPotentiallyRelevant(
        body: 'Rs. 1000 credit received',
        address: 'SPAM_SENDER',
        allowedSenderIds: allowed,
        blockedSenderIds: blocked,
      ), isFalse);

      // 5. No transaction keywords but has amount (not relevant)
      expect(SmsParser.isPotentiallyRelevant(
        body: 'The price is LKR 500 for the item.',
        address: 'FRIEND',
        allowedSenderIds: allowed,
        blockedSenderIds: blocked,
      ), isFalse);
    });
  });
}
