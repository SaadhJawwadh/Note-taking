import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/services/sms_service.dart';
import 'package:telephony/telephony.dart';

void main() {
  test('Parses Commercial Bank messages correctly', () {
    final sms1Map = {
      'address': 'COMBANK',
      'body':
          'Credit for Rs. 248,668.00 to 8152016836 at 15:16 at DIGITAL BANKING DIVISION',
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    final sms1 = SmsMessage.fromMap(
        sms1Map, [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE]);

    final sms2Map = {
      'address': 'COMBANK',
      'body':
          'Dear Cardholder, Purchase at KOKO COLOMBO 03 LK for LKR 10,299.66 on 26/02/26 07:21 AM has been authorised on your debit card ending #4525.',
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    final sms2 = SmsMessage.fromMap(
        sms2Map, [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE]);

    final sms3Map = {
      'address': 'ComBank_Q+',
      'body':
          'Dear Customer,Your Fund Transfer of Rs. 5,600.00 to Account Number XXXXXXXX7341 is successful. Reference Number is 605707618054.',
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    final sms3 = SmsMessage.fromMap(
        sms3Map, [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE]);

    final t1 = SmsService.parseMessage(sms1);
    expect(t1, isNotNull, reason: 'SMS 1 should parse');

    final t2 = SmsService.parseMessage(sms2);
    expect(t2, isNotNull, reason: 'SMS 2 should parse');

    final t3 = SmsService.parseMessage(sms3);
    expect(t3, isNotNull, reason: 'SMS 3 should parse');
  });
}
