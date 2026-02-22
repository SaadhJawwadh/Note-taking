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

// ── PII — always strip before building description ────────────────────────────
/// Masked card / account numbers (e.g. *1234, ending 5678, a/c *xx1234, xxxx1234)
final _piiCardRegex = RegExp(
  r'\*\d{4,}'
  r'|ending\s+\d{4,}'
  r'|\bno\.?\s*\d{4,}'
  r'|\ba\/c\s*[\d*x]+'
  r'|\bxxxx\d{4,}'
  r'|\b\d{16}\b',
  caseSensitive: false,
);

/// Reference / auth codes (ref: ABC123, txn id: 123, auth code: X)
final _piiRefRegex = RegExp(
  r'\bref(?:\s*no\.?)?\s*:?\s*\w+'
  r'|\btxn(?:\s*id)?\s*:?\s*[\w\d]+'
  r'|\bauth(?:\s*code)?\s*:?\s*[\w\d]+'
  r'|\btran\s*id\s*:?\s*[\w\d]+',
  caseSensitive: false,
);

/// Balance lines (Avl Bal / Available Balance / Bal: X)
final _piiBalanceRegex = RegExp(
  r'avl\s*bal[^\d]*[\d,]+(?:\.\d{1,2})?'
  r'|avail?(?:able)?\s*bal(?:ance)?\s*:?\s*(?:lkr|rs\.?)?\s*[\d,]+(?:\.\d{1,2})?'
  r'|\bbal\s*:?\s*(?:lkr|rs\.?)?\s*[\d,]+(?:\.\d{1,2})?',
  caseSensitive: false,
);

/// Dates, times, local phone numbers
final _piiDateTimePhoneRegex = RegExp(
  r'\b\d{1,2}[-/]\d{1,2}[-/]\d{2,4}\b'
  r'|\b\d{1,2}:\d{2}\s*(?:[ap]m)?\b'
  r'|\b0\d{9}\b'
  r'|\b\d{11}\b',
  caseSensitive: false,
);

/// Noise words stripped as a last-resort fallback
final _noiseWordsRegex = RegExp(
  r'\b(?:your|has\s+been|dear|valued|customer|card|account|transaction|'
  r'bank|balance|available|avl|bal|via|the|please|contact|call|'
  r'if\s+not\s+you|do\s+not\s+share)\b',
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
    // 1. Strip PII so nothing sensitive survives into the description
    var text = body;
    text = text.replaceAll(_piiBalanceRegex, '');
    text = text.replaceAll(_piiCardRegex, '');
    text = text.replaceAll(_piiRefRegex, '');
    text = text.replaceAll(_piiDateTimePhoneRegex, '');
    text = text.replaceAll(_amountRegex, '');

    // 2. Try to pull out just the vendor / merchant name
    //    Patterns: "at <Merchant>", "for <Merchant>", "from <Merchant>"
    //    Terminated by punctuation, balance/ref keywords, or end-of-string.
    const terminators =
        r"(?=\s*(?:[,.\n]|$|\bref\b|\bauth\b|\bavl\b|\bbal\b|\bon\b|\bvia\b|\bif\b))";

    RegExpMatch? m;

    // "at X" — most reliable for POS / digital payments
    m = RegExp(
      r"\bat\s+([A-Za-z][A-Za-z0-9\s&'\-\.]{1,35}?)" + terminators,
      caseSensitive: false,
    ).firstMatch(text);

    // "for X" — bill payments, transfers
    m ??= RegExp(
      r"\bfor\s+([A-Za-z][A-Za-z0-9\s&'\-\.]{1,35}?)" + terminators,
      caseSensitive: false,
    ).firstMatch(text);

    // "from X" — income / inward transfers
    m ??= RegExp(
      r"\bfrom\s+(?!(?:your|the|our|my)\b)([A-Za-z][A-Za-z0-9\s&'\-\.]{1,35}?)" +
          terminators,
      caseSensitive: false,
    ).firstMatch(text);

    if (m != null) {
      final candidate =
          m.group(1)!.trim().replaceAll(RegExp(r'\s{2,}'), ' ');
      if (candidate.length >= 2) return _cleanTitle(candidate);
    }

    // 3. Fallback: strip direction and noise words, return whatever is left
    text = text.replaceAll(_debitRegex, '');
    text = text.replaceAll(_creditRegex, '');
    text = text.replaceAll(_noiseWordsRegex, '');
    text = text.replaceAll(RegExp(r"[^A-Za-z0-9\s&'\-]"), ' ');
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    if (text.length > 50) text = text.substring(0, 50).trim();
    if (text.isNotEmpty) return _cleanTitle(text);

    return sender;
  }

  /// Title-cases each word; short ALL-CAPS tokens (≤4 chars) are kept as-is
  /// so acronyms like HNB, BOC, ATM survive the transformation.
  static String _cleanTitle(String s) {
    return s
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) {
          if (w.length <= 4 &&
              w == w.toUpperCase() &&
              RegExp(r'^[A-Z]+$').hasMatch(w)) {
            return w; // preserve acronym
          }
          return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
        })
        .join(' ');
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
