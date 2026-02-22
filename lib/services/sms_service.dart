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
  r'\b(credit(?:ed)?|received|deposited|transferred\s+to\s+you|credited\s+to|'
  r'salary|payment\s+received|fund\s+transfer|incoming\s+transfer|cash\s+deposit)\b',
  caseSensitive: false,
);

// ── Cancellation — skip entirely ─────────────────────────────────────────────
final _cancellationRegex = RegExp(
  r'\b(cancelled|cancellation|transaction\s+failed|declined|not\s+processed|unsuccessful)\b',
  caseSensitive: false,
);

// ── Reversal — credit-back that should remove the original expense ────────────
final _reversalRegex = RegExp(
  r'\b(reversal|reversed|refund(?:ed)?|chargeback|credit\s+back|amount\s+refunded|money\s+returned)\b',
  caseSensitive: false,
);

// ── Promotional messages — skip when no real direction keyword present ────────
final _promotionalRegex = RegExp(
  r'\b(offer|win|congratulations|promo|discount|exclusive|earn\s+\d+\s+points|'
  r'cashback\s+up\s+to|get\s+\d+%|voucher|reward\s+point)\b',
  caseSensitive: false,
);

// ── Boilerplate patterns to strip from description ───────────────────────────
final _boilerplateRegex = RegExp(
  r'\b(your|account|ending|no\.|has been|debited|credited|for|on|ref\s*:?\s*\w+|balance|available|dear|customer|valued|transaction|via|from|to\s+a/c|a/c|avl\s*bal|auth\s*code|code|on\s+\d{2}[-/]\d{2}[-/]\d{2,4})\b',
  caseSensitive: false,
);

/// Sentinel value stored in the category field to flag a reversal transaction.
/// Handled immediately after DB insert; never left permanently in the DB.
const _reversalSentinel = '__reversal__';

// ── Top-level background handler — MUST be top-level (not a class member) ────
@pragma('vm:entry-point')
Future<void> onBackgroundSms(SmsMessage message) async {
  final transaction = SmsService.parseMessage(message);
  if (transaction == null || transaction.smsId == null) return;
  final inserted = await DatabaseHelper.instance.createSmsTransaction(transaction);
  if (inserted == null) return;
  if (inserted.category == _reversalSentinel) {
    final target = await DatabaseHelper.instance
        .findReversalTarget(inserted.amount, inserted.date);
    if (target != null) {
      await DatabaseHelper.instance.deleteTransaction(target.id!);
    }
    await DatabaseHelper.instance.deleteTransaction(inserted.id!);
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

    // Skip cancelled or failed transactions
    if (_cancellationRegex.hasMatch(body)) return null;

    // Must be from a known bank sender OR contain a direction keyword
    final isKnownBank = _bankSenders.any((s) => sender.contains(s));
    final isDebit = _debitRegex.hasMatch(body);
    final isCredit = _creditRegex.hasMatch(body);
    if (!isKnownBank && !isDebit && !isCredit) return null;

    // Skip promotional messages that have no actual debit/credit direction
    if (_promotionalRegex.hasMatch(body) && !isDebit && !isCredit) return null;

    // Extract amount (required for a valid transaction)
    final amountMatch = _amountRegex.firstMatch(body);
    if (amountMatch == null) return null;
    final amountStr = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return null;

    // Skip if no direction keyword at all
    if (!isDebit && !isCredit) return null;

    // Detect reversal: credit-back with reversal language and no debit keyword
    final isReversal = _reversalRegex.hasMatch(body) && isCredit && !isDebit;

    // Debit takes priority when both are present
    final isExpense = isDebit;

    // Build a clean description
    final description = _buildDescription(body, sender);
    final category = isReversal
        ? _reversalSentinel
        : TransactionCategory.fromDescriptionCached('$description $body');

    // SMS timestamp or now
    final date = message.date != null
        ? DateTime.fromMillisecondsSinceEpoch(message.date!)
        : DateTime.now();

    // Stable unique ID for deduplication
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
    var desc = body.replaceAll(_amountRegex, '');
    desc = desc.replaceAll(_boilerplateRegex, ' ');
    desc = desc.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    desc = desc.replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'), '').trim();
    if (desc.length > 60) desc = desc.substring(0, 60).trim();
    if (desc.isEmpty) desc = sender;
    return desc;
  }

  // ── Sync inbox ───────────────────────────────────────────────────────────
  /// Reads SMS received on or after [from], parses bank messages, and creates
  /// new transactions. Returns the count of net new transactions imported.
  /// Reversals delete the matching original expense and are not counted.
  static Future<int> syncInboxFrom(DateTime from) async {
    if (!await hasPermission()) return 0;

    final fromMs = from.millisecondsSinceEpoch;
    final messages = await _telephony.getInboxSms(
      columns: [
        SmsColumn.ID,
        SmsColumn.ADDRESS,
        SmsColumn.BODY,
        SmsColumn.DATE,
      ],
      filter: SmsFilter.where(SmsColumn.DATE).greaterThanOrEqualTo('$fromMs'),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.ASC)],
    );

    int imported = 0;
    for (final msg in messages) {
      final t = parseMessage(msg);
      if (t == null || t.smsId == null) continue;
      final inserted = await DatabaseHelper.instance.createSmsTransaction(t);
      if (inserted == null) continue; // duplicate smsId
      if (inserted.category == _reversalSentinel) {
        final target = await DatabaseHelper.instance
            .findReversalTarget(inserted.amount, inserted.date);
        if (target != null) {
          await DatabaseHelper.instance.deleteTransaction(target.id!);
        }
        await DatabaseHelper.instance.deleteTransaction(inserted.id!);
      } else {
        imported++;
      }
    }
    return imported;
  }

  // ── Real-time foreground listener ────────────────────────────────────────
  /// Starts listening for incoming SMS while the app is in the foreground.
  /// [onNew] is called for each successfully inserted (non-reversal) transaction.
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
