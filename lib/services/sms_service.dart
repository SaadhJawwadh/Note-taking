import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/database_helper.dart';
import '../data/transaction_model.dart';
import 'sms_parser.dart';
import 'sms_constants.dart';

class SmsService {
  static final Telephony telephony = Telephony.instance;

  static Future<void> _handleNewSms(SmsMessage sms) async {
    final transaction = SmsParser.parseMessage(
      body: sms.body ?? '',
      address: sms.address ?? '',
      messageId: sms.id,
      messageDate: sms.date,
      allowedSenderIds: _allowedSenderIds,
      blockedSenderIds: _blockedSenderIds,
      customExpenseRules: _customExpenseRules,
      customIncomeRules: _customIncomeRules,
    );
    if (transaction == null || transaction.smsId == null) {
      return;
    }
    if (await DatabaseHelper.instance.hasCrossSenderDuplicate(transaction.amount, transaction.date)) {
      return;
    }

    final inserted = await DatabaseHelper.instance.createSmsTransaction(transaction);
    if (inserted == null) {
      return;
    }

    if (transaction.category == SmsConstants.reversalSentinel) {
      final target = await DatabaseHelper.instance.findReversalTarget(transaction.amount, transaction.date);
      if (target != null) {
        await DatabaseHelper.instance.deleteTransaction(target.id!);
      }
    }
  }

  static Set<String> _allowedSenderIds = {};
  static Set<String> _blockedSenderIds = {};
  static var _customExpenseRules = <String>[];
  static var _customIncomeRules = <String>[];

  static Future<void> reloadSmsContacts() async {
    final contacts = await DatabaseHelper.instance.getAllSmsContacts();
    final allowed = <String>{};
    final blocked = <String>{};
    for (final c in contacts) {
      if (c.isBlocked) {
        blocked.addAll(c.senderIds.map((s) => s.toLowerCase()));
      } else {
        allowed.addAll(c.senderIds.map((s) => s.toLowerCase()));
      }
    }
    _allowedSenderIds = allowed;
    _blockedSenderIds = blocked;
    try {
      final prefs = await SharedPreferences.getInstance();
      _customExpenseRules = prefs.getStringList('customExpenseRules') ?? [];
      _customIncomeRules = prefs.getStringList('customIncomeRules') ?? [];
    } catch (_) {}
  }

  static Future<bool> requestPermissions() async => (await Permission.sms.request()).isGranted;

  static Future<bool> hasPermission() async => (await Permission.sms.status).isGranted;

  static Future<int> syncInboxFrom(DateTime from) async {
    if (!await hasPermission()) {
      return 0;
    }
    await reloadSmsContacts();

    final start = from.millisecondsSinceEpoch;

    final messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE, SmsColumn.ID],
      filter: SmsFilter.where(SmsColumn.DATE).greaterThanOrEqualTo(start.toString()),
    );

    int count = 0;
    for (var m in messages) {
      final t = SmsParser.parseMessage(
        body: m.body ?? '',
        address: m.address ?? '',
        messageId: m.id,
        messageDate: m.date,
        allowedSenderIds: _allowedSenderIds,
        blockedSenderIds: _blockedSenderIds,
        customExpenseRules: _customExpenseRules,
        customIncomeRules: _customIncomeRules,
      );
      if (t == null || t.smsId == null) {
        continue;
      }
      if (await DatabaseHelper.instance.hasCrossSenderDuplicate(t.amount, t.date)) {
        continue;
      }

      final inserted = await DatabaseHelper.instance.createSmsTransaction(t);
      if (inserted == null) {
        continue;
      }
      count++;

      if (t.category == SmsConstants.reversalSentinel) {
        final target = await DatabaseHelper.instance.findReversalTarget(t.amount, t.date);
        if (target != null) {
          await DatabaseHelper.instance.deleteTransaction(target.id!);
        }
      }
    }
    return count;
  }

  static void listenForSms({required Function(TransactionModel) onNew}) {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        await reloadSmsContacts();
        await _handleNewSms(message);
        final t = SmsParser.parseMessage(
          body: message.body ?? '',
          address: message.address ?? '',
          messageId: message.id,
          messageDate: message.date,
          allowedSenderIds: _allowedSenderIds,
          blockedSenderIds: _blockedSenderIds,
          customExpenseRules: _customExpenseRules,
          customIncomeRules: _customIncomeRules,
        );
        if (t != null) {
          onNew(t);
        }
      },
      onBackgroundMessage: backgroundMessageHandler,
    );
  }
}

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  // We can't access SharedPreferences/DB config easily in background without reloading them, but for basic logging we can try.
  // Ideally this would reload prefs in the isolate or just pass empty lists if not available.
  final transaction = SmsParser.parseMessage(
    body: message.body ?? '',
    address: message.address ?? '',
    messageId: message.id,
    messageDate: message.date,
    allowedSenderIds: {},
    blockedSenderIds: {},
    customExpenseRules: [],
    customIncomeRules: [],
  );
  if (transaction != null) {
    await DatabaseHelper.instance.createSmsTransaction(transaction);
  }
}
