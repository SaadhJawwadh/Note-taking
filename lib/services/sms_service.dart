import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/transaction_model.dart';
import '../data/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sms_constants.dart';
import 'sms_parser.dart';

@pragma('vm:entry-point')
Future<void> onBackgroundSms(SmsMessage message) async {
  await SmsService.reloadSmsContacts();
  final transaction = SmsService.parseMessage(message);
  if (transaction == null || transaction.smsId == null) return;
  if (await DatabaseHelper.instance.hasCrossSenderDuplicate(transaction.amount, transaction.date)) return;
  final inserted = await DatabaseHelper.instance.createSmsTransaction(transaction);
  if (inserted == null) return;
  if (inserted.category == SmsConstants.reversalSentinel) {
    final target = await DatabaseHelper.instance.findReversalTarget(inserted.amount, inserted.date);
    if (target != null) await DatabaseHelper.instance.deleteTransaction(target.id!);
    await DatabaseHelper.instance.deleteTransaction(inserted.id!);
  }
}

class SmsService {
  SmsService._();

  static final _telephony = Telephony.instance;
  static var _allowedSenderIds = <String>{};
  static var _blockedSenderIds = <String>{};
  static var _customExpenseRules = <String>[];
  static var _customIncomeRules = <String>[];

  static Future<void> reloadSmsContacts() async {
    final contacts = await DatabaseHelper.instance.getAllSmsContacts();
    final allowed = <String>{};
    final blocked = <String>{};
    for (final c in contacts) {
      if (c.isBlocked) blocked.addAll(c.senderIds.map((s) => s.toLowerCase()));
      else allowed.addAll(c.senderIds.map((s) => s.toLowerCase()));
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
  static Future<bool> hasPermission() async => await Permission.sms.isGranted;

  static TransactionModel? parseMessage(SmsMessage message) {
    return SmsParser.parseMessage(
      body: message.body ?? '',
      address: message.address ?? '',
      messageId: message.id,
      messageDate: message.date,
      allowedSenderIds: _allowedSenderIds,
      blockedSenderIds: _blockedSenderIds,
      customExpenseRules: _customExpenseRules,
      customIncomeRules: _customIncomeRules,
    );
  }

  static Future<int> syncInboxFrom(DateTime from) async {
    if (!await hasPermission()) return 0;
    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ID, SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.DATE).greaterThanOrEqualTo('${from.millisecondsSinceEpoch}'),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.ASC)],
    );

    int imported = 0;
    for (final msg in messages) {
      final t = parseMessage(msg);
      if (t == null || t.smsId == null) continue;
      if (await DatabaseHelper.instance.hasCrossSenderDuplicate(t.amount, t.date)) continue;
      final inserted = await DatabaseHelper.instance.createSmsTransaction(t);
      if (inserted == null) continue;
      if (inserted.category == SmsConstants.reversalSentinel) {
        final target = await DatabaseHelper.instance.findReversalTarget(inserted.amount, inserted.date);
        if (target != null) await DatabaseHelper.instance.deleteTransaction(target.id!);
        await DatabaseHelper.instance.deleteTransaction(inserted.id!);
      } else {
        imported++;
      }
    }
    return imported;
  }

  static void startForegroundListener(void Function(TransactionModel) onNew) {
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        final t = parseMessage(message);
        if (t != null) onNew(t);
      },
      onBackgroundMessage: onBackgroundSms,
      listenInBackground: true,
    );
  }
}
