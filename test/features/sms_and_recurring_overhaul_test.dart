import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/services/sms_parser.dart';
import 'package:note_taking_app/data/category_constants.dart';
import 'package:note_taking_app/data/recurring_rule_model.dart';
import 'package:note_taking_app/features/finances/services/spending_forecast_service.dart';
import 'package:note_taking_app/data/transaction_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SMS Parser Overhaul & Promotional Rejection Tests', () {
    const allowed = <String>{'combank', 'hnb', 'sampath', 'card_alerts'};
    const blocked = <String>{'spam_bank'};

    test('Strictly rejects promotional SMS with conditional spend thresholds', () {
      final promos = [
        'Enjoy 20% discount on purchases over Rs. 3800 at Pizza Hut with your Commercial Bank Card!',
        'KFC Dining Offer! Save up to Rs. 4,950 on minimum spend of Rs. 5000 this weekend.',
        'Debit Card 15 Day Cashback: Get Rs. 5,000 cashback when you spend Rs. 50,000 this month.',
        'Congratulations! You are eligible for personal loan up to Rs. 500,000. Apply now at any branch.',
        'Special deal at Dominos: Buy 1 get 1 free on spend of Rs. 2500 using promo code PIZZA50.',
      ];

      for (final msg in promos) {
        final parsed = SmsParser.parseMessage(
          body: msg,
          address: 'COMBANK',
          messageId: 1,
          messageDate: DateTime.now().millisecondsSinceEpoch,
          allowedSenderIds: allowed,
          blockedSenderIds: blocked,
          customExpenseRules: [],
          customIncomeRules: [],
        );
        expect(parsed, isNull, reason: 'Expected promo to be rejected: "$msg"');
        expect(SmsParser.isPotentiallyRelevant(
          body: msg,
          address: 'COMBANK',
          allowedSenderIds: allowed,
          blockedSenderIds: blocked,
        ), isFalse, reason: 'Expected promo to not be potentially relevant: "$msg"');
      }
    });

    test('Correctly parses genuine executed purchase receipts without capturing available balance', () {
      const msg = 'Your A/C *1234 has been debited for LKR 2,450.00 at Keells Super on 2026-08-24. Avail Bal LKR 120,000.00';
      final parsed = SmsParser.parseMessage(
        body: msg,
        address: 'COMBANK',
        messageId: 2,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: allowed,
        blockedSenderIds: blocked,
        customExpenseRules: [],
        customIncomeRules: [],
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 2450.0);
      expect(parsed.isExpense, isTrue);
      expect(parsed.category, CategoryConstants.food);
    });

    test('Correctly categorizes Hardware under Shopping', () {
      const msg = 'Txn of LKR 14,500.00 approved at SNS United Hardware on card *5678. Avail Bal LKR 80,000.00';
      final parsed = SmsParser.parseMessage(
        body: msg,
        address: 'COMBANK',
        messageId: 3,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: allowed,
        blockedSenderIds: blocked,
        customExpenseRules: [],
        customIncomeRules: [],
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 14500.0);
      expect(parsed.isExpense, isTrue);
      expect(parsed.category, CategoryConstants.shopping);
    });

    test('Accurately identifies inward transfers and credits as Income', () {
      // 1. Transfer from person
      const msgTransfer = 'Transfer from JAWWADH LKR 100,000.00 credited to your A/C *4321. Avail Bal LKR 150,000.00';
      final parsedTransfer = SmsParser.parseMessage(
        body: msgTransfer,
        address: 'COMBANK',
        messageId: 4,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: allowed,
        blockedSenderIds: blocked,
        customExpenseRules: [],
        customIncomeRules: [],
      );
      expect(parsedTransfer, isNotNull);
      expect(parsedTransfer!.amount, 100000.0);
      expect(parsedTransfer.isExpense, isFalse); // Inward credit / income

      // 2. Direct credit
      const msgCredit = 'Credit of LKR 80,000.00 to your Card *9999 on 26-May. Avail Bal LKR 200,000.00';
      final parsedCredit = SmsParser.parseMessage(
        body: msgCredit,
        address: 'COMBANK',
        messageId: 5,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: allowed,
        blockedSenderIds: blocked,
        customExpenseRules: [],
        customIncomeRules: [],
      );
      expect(parsedCredit, isNotNull);
      expect(parsedCredit!.amount, 80000.0);
      expect(parsedCredit.isExpense, isFalse);

      // 3. Digital banking deposit
      const msgDeposit = 'Deposit from DIGITAL BANKING DIVISION LKR 15,000.00 received.';
      final parsedDeposit = SmsParser.parseMessage(
        body: msgDeposit,
        address: 'COMBANK',
        messageId: 6,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: allowed,
        blockedSenderIds: blocked,
        customExpenseRules: [],
        customIncomeRules: [],
      );
      expect(parsedDeposit, isNotNull);
      expect(parsedDeposit!.amount, 15000.0);
      expect(parsedDeposit.isExpense, isFalse);
    });

    test('Accurately identifies internal self-transfers and assigns Transfer category', () {
      const msgSelf = 'Transfer to SAADH TAB LKR 250,000.00 from A/C *1111 on 27-Jun. Avail Bal LKR 30,000.00';
      final parsedSelf = SmsParser.parseMessage(
        body: msgSelf,
        address: 'COMBANK',
        messageId: 7,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: allowed,
        blockedSenderIds: blocked,
        customExpenseRules: [],
        customIncomeRules: [],
      );
      expect(parsedSelf, isNotNull);
      expect(parsedSelf!.amount, 250000.0);
      expect(parsedSelf.category, CategoryConstants.transfer);
    });
  });

  group('Recurring Rule Model & Deduplication Tests', () {
    test('RecurringRule copyWith accurately updates properties without mutation', () {
      final rule = RecurringRule(
        id: 'rule-1',
        description: 'Netflix',
        amount: 2500.0,
        category: CategoryConstants.subscriptions,
        isExpense: true,
        frequency: RecurringFrequency.monthly,
        nextDue: DateTime(2026, 9, 1),
      );

      final updated = rule.copyWith(
        amount: 2900.0,
        description: 'Netflix 4K Premium',
      );

      expect(updated.id, 'rule-1');
      expect(updated.description, 'Netflix 4K Premium');
      expect(updated.amount, 2900.0);
      expect(updated.category, CategoryConstants.subscriptions);
      expect(updated.frequency, RecurringFrequency.monthly);
      expect(updated.nextDue, DateTime(2026, 9, 1));
    });

    test('RecurringRule advance handles monthly progression with month-end clamping', () {
      final rule = RecurringRule(
        id: 'rule-2',
        description: 'Starlink',
        amount: 15000.0,
        category: CategoryConstants.subscriptions,
        isExpense: true,
        frequency: RecurringFrequency.monthly,
        nextDue: DateTime(2026, 1, 31),
      );

      final nextMonth = rule.advance(rule.nextDue);
      // February only has 28 days in non-leap 2026
      expect(nextMonth.month, 2);
      expect(nextMonth.day, 28);
    });
  });

  group('Spending Forecast & Transfer Exclusion Tests', () {
    test('Spending forecast excludes Transfer category transactions from monthly expense total', () {
      final now = DateTime(2026, 8, 15);
      final transactions = [
        TransactionModel(
          amount: 5000.0,
          description: 'Grocery Keells',
          date: DateTime(2026, 8, 5),
          isExpense: true,
          category: CategoryConstants.food,
        ),
        TransactionModel(
          amount: 250000.0,
          description: 'Transfer to SAADH TAB',
          date: DateTime(2026, 8, 10),
          isExpense: true,
          category: CategoryConstants.transfer, // Internal self-transfer
        ),
        TransactionModel(
          amount: 3000.0,
          description: 'Uber ride',
          date: DateTime(2026, 8, 12),
          isExpense: true,
          category: CategoryConstants.transport,
        ),
      ];

      final forecast = SpendingForecastService.calculateMonthlyForecast(
        transactions: transactions,
        categoryBudgets: {
          CategoryConstants.food: 30000.0,
          CategoryConstants.transport: 15000.0,
        },
        referenceDate: now,
      );

      // Monthly spent should be 5000 + 3000 = 8000, NOT 258000!
      expect(forecast.currentMonthSpent, 8000.0);
    });
  });

  group('Real-World Bank & Non-Financial SMS Sample Tests', () {
    const allowed = <String>{'combank', 'amana bank', 'amana', '1919'};

    test('National Fuel Pass (1919) quota notifications are correctly ignored as non-financial', () {
      final fuelSmsList = [
        'National Fuel Pass: TRN confirmed. 2026-07-30 09:29:47 BHE-6666 Quota used: 4.5L Weekly Balance: 3.500L Station code: 108829 (Resets on - 2026-08-02)',
        'National Fuel Pass: TRN confirmed. 2026-08-10 10:56:56 BHE-6666 Quota used: 3.1L Weekly Balance: 4.900L Station code: 108829 (Resets on - 2026-08-16)',
        'National Fuel Pass: TRN confirmed. 2026-08-20 19:18:27 BHE-6666 Quota used: 2.4L Weekly Balance: 5.600L Station code: 100036 (Resets on - 2026-08-23)',
      ];

      for (final msg in fuelSmsList) {
        final parsed = SmsParser.parseMessage(
          body: msg,
          address: '1919',
          messageId: null,
          messageDate: null,
          allowedSenderIds: allowed,
          blockedSenderIds: const {},
          customExpenseRules: [],
          customIncomeRules: [],
        );
        expect(parsed, isNull, reason: 'Fuel pass quota message should not create financial transactions: $msg');
      }
    });

    test('Amana Bank informational and OTP messages are safely ignored', () {
      const infoMsg = "Dear Customer, We are happy to inform that the security features of the 'Your Bank' app has been further enhanced. We kindly request you to update the app on or before 22nd Aug 2026 to enjoy a seamless online banking experience. Simply open the app and click 'Update' on the pop-up message or visit the relevant App/Play store to complete the update.";
      const otpMsg = 'Your OTP is 984776. OTP is confidential. Do not share with anyone.Contact 0117756756 if you did not request for an OTP';

      final parsedInfo = SmsParser.parseMessage(
        body: infoMsg,
        address: 'Amana Bank',
        messageId: null,
        messageDate: null,
        allowedSenderIds: allowed,
        blockedSenderIds: const {},
        customExpenseRules: [],
        customIncomeRules: [],
      );
      expect(parsedInfo, isNull);

      final parsedOtp = SmsParser.parseMessage(
        body: otpMsg,
        address: 'Amana Bank',
        messageId: null,
        messageDate: null,
        allowedSenderIds: allowed,
        blockedSenderIds: const {},
        customExpenseRules: [],
        customIncomeRules: [],
      );
      expect(parsedOtp, isNull);
    });

    test('Amana Bank CEFTS self-transfer is accurately parsed to Transfer category', () {
      const trfMsg = 'IB CEFTS trf of LKR 15,000.00 & charge of LKR 25.00 (KOKO) to: SAADH COM debited from your A/C ***1001. Avail. Bal. LKR 63,926.44. Enq 0117756756';
      final parsed = SmsParser.parseMessage(
        body: trfMsg,
        address: 'Amana Bank',
        messageId: 10,
        messageDate: DateTime(2026, 8, 22, 19, 19).millisecondsSinceEpoch,
        allowedSenderIds: allowed,
        blockedSenderIds: const {},
        customExpenseRules: [],
        customIncomeRules: [],
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 15000.00);
      expect(parsed.category, CategoryConstants.transfer);
      expect(parsed.isExpense, isTrue);
    });

    test('COMBANK Credit and Debit Card Purchases are parsed with pristine merchant names', () {
      // 1. Credit receipt
      const creditMsg = 'Credit for Rs. 15,000.00 to 8152016836 at 19:18 at DIGITAL BANKING DIVISION';
      final parsedCredit = SmsParser.parseMessage(
        body: creditMsg,
        address: 'COMBANK',
        messageId: 11,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: allowed,
        blockedSenderIds: const {},
        customExpenseRules: [],
        customIncomeRules: [],
      );
      expect(parsedCredit, isNotNull);
      expect(parsedCredit!.amount, 15000.00);
      expect(parsedCredit.isExpense, isFalse); // Credit / Income

      // 2. KOKO Purchase
      const kokoMsg = 'Dear Cardholder, Purchase at KOKO COLOMBO 03 LK for LKR 11,200.67 on 22/08/26 07:19 PM has been authorised on your debit card ending #4525.';
      final parsedKoko = SmsParser.parseMessage(
        body: kokoMsg,
        address: 'COMBANK',
        messageId: 12,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: allowed,
        blockedSenderIds: const {},
        customExpenseRules: [],
        customIncomeRules: [],
      );
      expect(parsedKoko, isNotNull);
      expect(parsedKoko!.amount, 11200.67);
      expect(parsedKoko.isExpense, isTrue);
      expect(parsedKoko.category, CategoryConstants.payments);

      // 3. PickMe Food Purchase with phone number & country code noise
      const pickMeMsg = 'Dear Cardholder, Purchase at PickMe Food 0117433433 LK for LKR 599.00 on 22/08/26 08:46 PM has been authorised on your debit card ending #4525.';
      final parsedPickMe = SmsParser.parseMessage(
        body: pickMeMsg,
        address: 'COMBANK',
        messageId: 13,
        messageDate: DateTime.now().millisecondsSinceEpoch,
        allowedSenderIds: allowed,
        blockedSenderIds: const {},
        customExpenseRules: [],
        customIncomeRules: [],
      );
      expect(parsedPickMe, isNotNull);
      expect(parsedPickMe!.amount, 599.00);
      expect(parsedPickMe.isExpense, isTrue);
      expect(parsedPickMe.category, CategoryConstants.food);
      // Clean merchant name without phone number or LK suffix
      expect(parsedPickMe.description.contains('0117433433'), isFalse);
      expect(parsedPickMe.description.toLowerCase().contains('pickme food'), isTrue);
    });
  });
}
