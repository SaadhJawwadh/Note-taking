import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/transaction_model.dart';
import '../data/database_helper.dart';
import '../data/transaction_category.dart';

// ── Bank sender IDs whitelisted for Sri Lanka ────────────────────────────────
const _bankSenders = {
  // Commercial Bank
  'COMBANK', 'Comm-Bank', 'CBSL',
  // Peoples Bank
  'PEOBANK', 'PeoplesB', 'PBOCSL', 'PEOPLBK',
  // HNB
  'HNB', 'HNBANK', 'HNBAlerts',
  // Sampath Bank
  'SAMPATH', 'Sampath', 'SAMPTBK',
  // BOC
  'BOCCSL', 'BOC', 'BOCSL',
  // NDB
  'NDB', 'NDBBANK',
  // Seylan Bank
  'SEYLAN', 'Seybank', 'SEYLNBK',
  // Amana Bank
  'AMANABNK', 'AMANA', 'AMANABK',
};

// ── Amount extraction ────────────────────────────────────────────────────────
// Matches: "LKR 1,500.00", "Rs. 1500", "Rs1500.00", "LKR1500"
final _amountRegex = RegExp(
  r'(?:LKR|Rs\.?)\s*([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);

// ── Direction keywords ───────────────────────────────────────────────────────
final _debitRegex = RegExp(
  r'\b(debit(?:ed)?|withdrawn|withdrawal|spent|charged|payment(?:\s+of)?)\b',
  caseSensitive: false,
);
final _creditRegex = RegExp(
  r'\b(credit(?:ed)?|received|deposited|transferred\s+to\s+you|credited\s+to)\b',
  caseSensitive: false,
);

// ── Boilerplate patterns to strip from description ───────────────────────────
final _boilerplateRegex = RegExp(
  r'\b(your|account|ending|no\.|has been|debited|credited|for|on|ref\s*:?\s*\w+|balance|available|dear|customer|valued|transaction|via|from|to\s+a/c|a/c|avl\s*bal|auth\s*code|code|on\s+\d{2}[-/]\d{2}[-/]\d{2,4})\b',
  caseSensitive: false,
);

// ── Top-level background handler — MUST be top-level (not a class member) ────
// Registered before runApp in main.dart via Telephony.backgroundSmsReceiver
@pragma('vm:entry-point')
Future<void> onBackgroundSms(SmsMessage message) async {
  final transaction = SmsService.parseMessage(message);
  if (transaction == null || transaction.smsId == null) return;
  final exists = await DatabaseHelper.instance.smsExists(transaction.smsId!);
  if (!exists) {
    await DatabaseHelper.instance.createTransaction(transaction);
  }
}

class SmsService {
  SmsService._();

  static final _telephony = Telephony.instance;

  // ── Permission helpers ───────────────────────────────────────────────────
  static Future<bool> requestPermissions() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  // ── Parse one SMS → TransactionModel? ───────────────────────────────────
  static TransactionModel? parseMessage(SmsMessage message) {
    final body = message.body ?? '';
    final sender = message.address ?? '';

    if (body.trim().isEmpty) return null;

    // Must be from a known bank sender OR contain debit/credit keywords
    final isKnownBank = _bankSenders.any((s) => sender.contains(s));
    final hasDirection = _debitRegex.hasMatch(body) || _creditRegex.hasMatch(body);
    if (!isKnownBank && !hasDirection) return null;

    // Extract amount (required for a valid transaction)
    final amountMatch = _amountRegex.firstMatch(body);
    if (amountMatch == null) return null;
    final amountStr = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return null;

    // Determine direction — debit takes priority; skip if ambiguous
    final isDebit = _debitRegex.hasMatch(body);
    final isCredit = _creditRegex.hasMatch(body);
    if (!isDebit && !isCredit) return null;
    final isExpense = isDebit;

    // Build a clean description
    final description = _buildDescription(body, sender);
    final category = TransactionCategory.fromDescription('$description $body');

    // SMS timestamp or now
    final date = message.date != null
        ? DateTime.fromMillisecondsSinceEpoch(message.date!)
        : DateTime.now();

    // Stable unique ID for deduplication.
    // Prefer the message's own integer ID; fall back to a hash of the body
    // so two different messages can't share the same smsId even if the
    // Android SMS store returns null metadata.
    final msgId = message.id;
    final msgDate = message.date ?? DateTime.now().millisecondsSinceEpoch;
    final smsId =
        msgId != null ? '${msgId}_$msgDate' : 'hash_${body.hashCode}_$msgDate';

    return TransactionModel(
      amount: amount,
      description: description,
      date: date,
      isExpense: isExpense,
      category: category,
      smsId: smsId,
    );
  }

  static String _buildDescription(String body, String sender) {
    // Strip amount patterns first
    var desc = body.replaceAll(_amountRegex, '');
    // Strip boilerplate keywords
    desc = desc.replaceAll(_boilerplateRegex, ' ');
    // Collapse whitespace and trim
    desc = desc.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    // Remove leading/trailing punctuation
    desc = desc.replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'), '').trim();

    if (desc.length > 60) desc = desc.substring(0, 60).trim();
    if (desc.isEmpty) desc = sender;
    return desc;
  }

  // ── Sync inbox ───────────────────────────────────────────────────────────
  /// Reads the full SMS inbox, parses bank messages, and creates new transactions.
  /// Returns the count of newly imported transactions.
  static Future<int> syncInbox() async {
    if (!await hasPermission()) return 0;

    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ID, SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.ASC)],
    );

    int imported = 0;
    for (final msg in messages) {
      final t = parseMessage(msg);
      if (t == null || t.smsId == null) continue;
      final exists = await DatabaseHelper.instance.smsExists(t.smsId!);
      if (!exists) {
        await DatabaseHelper.instance.createTransaction(t);
        imported++;
      }
    }
    return imported;
  }

  /// Reads SMS received on or after [from], parses bank messages, and creates
  /// new transactions. Returns the count of newly imported transactions.
  static Future<int> syncInboxFrom(DateTime from) async {
    if (!await hasPermission()) return 0;

    final fromMs = from.millisecondsSinceEpoch;
    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ID, SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.DATE).greaterThanOrEqualTo('$fromMs'),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.ASC)],
    );

    int imported = 0;
    for (final msg in messages) {
      final t = parseMessage(msg);
      if (t == null || t.smsId == null) continue;
      final exists = await DatabaseHelper.instance.smsExists(t.smsId!);
      if (!exists) {
        await DatabaseHelper.instance.createTransaction(t);
        imported++;
      }
    }
    return imported;
  }

  // ── Real-time foreground listener ────────────────────────────────────────
  /// Starts listening for incoming SMS while the app is in the foreground.
  /// Calls [onNew] for each bank transaction detected.
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
