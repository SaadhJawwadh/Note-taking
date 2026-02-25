import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/transaction_model.dart';
import '../data/database_helper.dart';
import '../data/transaction_category.dart';

// ── Default bank sender IDs (banks only — actual debit/credit confirmations) ──
// Non-bank services (KOKO, wallets, etc.) belong in the user-managed whitelist.
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
  // Nations Trust Bank
  'NTB', 'NTBBANK',
  // LOLC Finance
  'LOLC',
};

// ── Human-readable name for known bank senders ────────────────────────────────
const _senderToBankName = <String, String>{
  'COMBANK': 'Commercial Bank',
  'Comm-Bank': 'Commercial Bank',
  'CBSL': 'Commercial Bank',
  'PEOBANK': 'Peoples Bank',
  'PeoplesB': 'Peoples Bank',
  'PBOCSL': 'Peoples Bank',
  'PEOPLBK': 'Peoples Bank',
  'HNB': 'HNB',
  'HNBANK': 'HNB',
  'HNBAlerts': 'HNB',
  'SAMPATH': 'Sampath Bank',
  'Sampath': 'Sampath Bank',
  'SAMPTBK': 'Sampath Bank',
  'BOCCSL': 'BOC',
  'BOC': 'BOC',
  'BOCSL': 'BOC',
  'NDB': 'NDB Bank',
  'NDBBANK': 'NDB Bank',
  'SEYLAN': 'Seylan Bank',
  'Seybank': 'Seylan Bank',
  'SEYLNBK': 'Seylan Bank',
  'AMANABNK': 'Amana Bank',
  'AMANA': 'Amana Bank',
  'AMANABK': 'Amana Bank',
  'NTB': 'Nations Trust Bank',
  'NTBBANK': 'Nations Trust Bank',
  'LOLC': 'LOLC Finance',
};

// ── Amount extraction ─────────────────────────────────────────────────────────
// Primary: "LKR 1,500.00", "Rs. 1500", "Rs1500.00", "LKR1500"
final _amountRegex = RegExp(
  r'(?:LKR|Rs\.?)\s*([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);

// Fallback: bare number after "of" for instalment/due messages (e.g. "of 7895.98")
final _bareAmountRegex = RegExp(
  r'\bof\s+([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);

// ── Transaction type detection ────────────────────────────────────────────────
final _depositRegex = RegExp(
  r'\b(deposit(?:ed)?|crm\s+deposit|cash\s+deposit)\b',
  caseSensitive: false,
);

final _purchaseRegex = RegExp(
  r'\b(purchase(?:d)?|authorised|authorized)\b',
  caseSensitive: false,
);

final _instalmentRegex = RegExp(
  r'\b(instalment|installment|emi|monthly\s+payment)\b',
  caseSensitive: false,
);

// ── Due-reminder detection — skip these unless a real debit keyword is present
// KOKO and similar services send "due tomorrow/today" reminders daily.
// These are NOT transactions — the actual debit comes from the bank.
final _dueReminderRegex = RegExp(
  r'\b(due\s+tomorrow|due\s+today|due\s+in\s+\d+|payment\s+is\s+due|is\s+due\s+on)\b',
  caseSensitive: false,
);

final _withdrawalRegex = RegExp(
  r'\b(withdrawn|withdrawal|atm\s+withdrawal|atm\s+debit)\b',
  caseSensitive: false,
);

final _transferRegex = RegExp(
  r'\b(fund\s+transfer|wire\s+transfer|inter\s+bank\s+transfer|transferred\s+to)\b',
  caseSensitive: false,
);

// ── Direction keywords ────────────────────────────────────────────────────────
final _debitRegex = RegExp(
  r'\b(debit(?:ed)?|withdrawn|withdrawal|spent|charged|purchase(?:d)?|'
  r'authorised|authorized|payment(?:\s+of)?)\b',
  caseSensitive: false,
);
final _creditRegex = RegExp(
  r'\b(credit(?:ed)?|received|deposited|deposit|transferred\s+to\s+you|credited\s+to|'
  r'salary|payment\s+received|fund\s+transfer|incoming\s+transfer|cash\s+deposit)\b',
  caseSensitive: false,
);

// ── Reversal — credit-back that should remove the original expense ────────────
final _reversalRegex = RegExp(
  r'\b(reversal|reversed|refund(?:ed)?|chargeback|credit\s+back|amount\s+refunded|'
  r'money\s+returned|returned\s+to\s+your\s+card|reversed\s+back)\b',
  caseSensitive: false,
);

// ── Cancellation — skip unless also a reversal ───────────────────────────────
final _cancellationRegex = RegExp(
  r'\b(cancelled|cancellation|transaction\s+failed|declined|not\s+processed|unsuccessful)\b',
  caseSensitive: false,
);

// ── Promotional messages — skip when no real direction keyword present ────────
final _promotionalRegex = RegExp(
  r'\b(offer|win|congratulations|promo|discount|exclusive|earn\s+\d+\s+points|'
  r'cashback\s+up\s+to|get\s+\d+%|voucher|reward\s+point)\b',
  caseSensitive: false,
);

// ── PII — always strip before building description ────────────────────────────
/// Masked card / account numbers
final _piiCardRegex = RegExp(
  r'\*\d{4,}'
  r'|ending\s+[#\*]?\d{4,}'
  r'|\bno\.?\s*\d{4,}'
  r'|\ba\/c\s*[\d*x]+'
  r'|\bxxxx\d{4,}'
  r'|\b\d{16}\b'
  r'|\b\d{4,}\*+\d{4,}\b',
  caseSensitive: false,
);

/// Reference / auth codes
final _piiRefRegex = RegExp(
  r'\bref(?:\s*no\.?)?\s*:?\s*\w+'
  r'|\btxn(?:\s*id)?\s*:?\s*[\w\d]+'
  r'|\bauth(?:\s*code)?\s*:?\s*[\w\d]+'
  r'|\btran\s*id\s*:?\s*[\w\d]+'
  r'|\border\s+id\s*:?\s*[\w\d]+'
  r'|\border\s*#?\s*[\d]+',
  caseSensitive: false,
);

/// Balance lines
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
  r'|\b\d{10,11}\b',
  caseSensitive: false,
);

/// URLs
final _urlRegex = RegExp(
  r'https?://\S+',
  caseSensitive: false,
);

/// Noise words stripped as a last-resort fallback
final _noiseWordsRegex = RegExp(
  r'\b(?:your|has\s+been|dear|valued|customer|card|account|transaction|'
  r'bank|balance|available|avl|bal|via|the|please|contact|call|'
  r'if\s+not\s+you|do\s+not\s+share|cardholder)\b',
  caseSensitive: false,
);

/// Sentinel value stored in category field to flag a reversal transaction.
/// Handled immediately after DB insert; never left permanently in the DB.
const _reversalSentinel = '__reversal__';

// ── Top-level background handler — MUST be top-level ─────────────────────────
@pragma('vm:entry-point')
Future<void> onBackgroundSms(SmsMessage message) async {
  // Reload SMS contacts so background isolate has latest blocked/allowed data.
  await SmsService.reloadSmsContacts();
  final transaction = SmsService.parseMessage(message);
  if (transaction == null || transaction.smsId == null) return;
  // Cross-sender dedup: skip if same amount exists within ±5 min
  if (await DatabaseHelper.instance
      .hasCrossSenderDuplicate(transaction.amount, transaction.date)) {
    return;
  }
  final inserted =
      await DatabaseHelper.instance.createSmsTransaction(transaction);
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

  // ── SMS contacts cache ───────────────────────────────────────────────────
  /// Flat set of sender IDs from non-blocked contacts (both built-in banks
  /// and custom user entries). Populated at startup and after edits.
  static var _allowedSenderIds = <String>{};

  /// Flat set of sender IDs from blocked contacts. Checked BEFORE allowed so
  /// blocking a bank effectively disables it.
  static var _blockedSenderIds = <String>{};

  /// Public constant so callers outside this file can check the sentinel value
  /// without coupling to an internal string literal.
  static const String reversalSentinel = _reversalSentinel;

  /// Reloads the SMS contacts cache from the database.
  /// Call at app startup and after any contact add/delete/block change.
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
  }

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

    // Check reversal FIRST — a cancelled+reversed message should still delete
    // the original transaction rather than just being ignored.
    final isReversal = _reversalRegex.hasMatch(body);
    final isCancellation = _cancellationRegex.hasMatch(body);

    // Skip only if cancelled and NOT also a reversal
    if (isCancellation && !isReversal) return null;

    // Must be from a known sender OR contain a direction keyword.
    // Blocked senders are always rejected first.
    final senderLower = sender.toLowerCase();
    if (_blockedSenderIds.any((s) => senderLower.contains(s))) return null;

    final isKnownSender = _bankSenders.any((s) => sender.contains(s)) ||
        _allowedSenderIds.any((s) => senderLower.contains(s));
    final isDebit = _debitRegex.hasMatch(body);
    final isCredit = _creditRegex.hasMatch(body);
    final hasInstalment = _instalmentRegex.hasMatch(body);

    if (!isKnownSender && !isDebit && !isCredit && !hasInstalment) return null;

    // Skip due-reminder SMS (e.g. "due tomorrow", "due today") that do NOT
    // contain an actual debit confirmation keyword. KOKO and similar services
    // send these daily; the real debit arrives later from the bank directly.
    if (_dueReminderRegex.hasMatch(body) && !isDebit) return null;

    // Skip promotional messages with no actual direction
    if (_promotionalRegex.hasMatch(body) &&
        !isDebit &&
        !isCredit &&
        !hasInstalment) {
      return null;
    }

    // Extract amount — try prefixed (LKR/Rs) first, then bare "of X" fallback
    double? amount;
    var amountMatch = _amountRegex.firstMatch(body);
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
    } else {
      final bareMatch = _bareAmountRegex.firstMatch(body);
      if (bareMatch != null) {
        amount = double.tryParse(bareMatch.group(1)!.replaceAll(',', ''));
      }
    }
    if (amount == null || amount <= 0) return null;

    // For a reversal we need an amount but direction may not matter
    if (!isReversal && !isDebit && !isCredit && !hasInstalment) return null;

    // Debit takes priority when both keywords present.
    // Instalment messages are always treated as expenses.
    final isExpense = isDebit || hasInstalment || (!isCredit && !isReversal);

    // Build human-readable description
    final description =
        _buildDescription(body, sender, amount, isExpense: isExpense);

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

  // ── Description builder ──────────────────────────────────────────────────
  /// Produces a short, meaningful description from an SMS body.
  /// Always includes the bank name (when known) and uses direction-aware
  /// prefixes for ambiguous fallback cases.
  ///
  /// Priority:
  ///   1. Deposit       → "Deposit of 10,000 in Commercial Bank"
  ///   2. Instalment    → "KOKO Instalment Simplytek"
  ///   3. Withdrawal    → "ATM Withdrawal 5,000 – Amana Bank"
  ///   4. Transfer      → "Transfer to John 5,000 – HNB"
  ///   5. Purchase      → "Purchase at PickMe Food 1,559 – Amana Bank"
  ///   6. Generic debit → "Payment at [Merchant] [amount] – Bank"
  ///   7. Fallback      → "Debit – [text] [amount] – Bank"
  static String _buildDescription(
    String body,
    String sender,
    double amount, {
    required bool isExpense,
  }) {
    final amountLabel = _formatAmount(amount);
    final bankName = _getBankName(sender);

    // Strip PII and noise for entity extraction
    var text = body;
    text = text.replaceAll(_urlRegex, '');
    text = text.replaceAll(_piiBalanceRegex, '');
    text = text.replaceAll(_piiCardRegex, '');
    text = text.replaceAll(_piiRefRegex, '');
    text = text.replaceAll(_piiDateTimePhoneRegex, '');
    text = text.replaceAll(_amountRegex, '');
    text = text.replaceAll(_bareAmountRegex, '');

    String desc;

    // ── 1. Deposit ────────────────────────────────────────────────────────
    if (_depositRegex.hasMatch(body)) {
      if (bankName != null) {
        return 'Deposit of $amountLabel in $bankName';
      }
      final throughMatch = RegExp(
        r'\bthrough\s+([A-Za-z][A-Za-z0-9\s\-]{1,25}?)\s+(?:BR|branch)\b',
        caseSensitive: false,
      ).firstMatch(body);
      if (throughMatch != null) {
        final branch = _cleanTitle(throughMatch.group(1)!.trim());
        return 'Deposit of $amountLabel via $branch';
      }
      return 'Deposit of $amountLabel';
    }

    // ── 2. Instalment / EMI ───────────────────────────────────────────────
    if (_instalmentRegex.hasMatch(body)) {
      final provider = bankName ?? _extractBodySender(body);
      final instalForRe = RegExp(
        r"\bfor\s+(?:your\s+)?([A-Za-z][A-Za-z0-9\s&'\-\.]{1,25}?)"
        r"\s+(?:order|purchase|plan|account)\b",
        caseSensitive: false,
      );
      final forMatch = instalForRe.firstMatch(body);
      final merchant =
          forMatch != null ? _cleanTitle(forMatch.group(1)!.trim()) : null;

      if (provider != null && merchant != null) {
        desc = '$provider Instalment $merchant';
      } else if (provider != null) {
        desc = '$provider Instalment $amountLabel';
      } else if (merchant != null) {
        desc = 'Instalment – $merchant $amountLabel';
      } else {
        desc = 'Instalment $amountLabel';
      }
      return _appendBankSuffix(desc, bankName);
    }

    // ── 3. ATM Withdrawal ─────────────────────────────────────────────────
    if (_withdrawalRegex.hasMatch(body)) {
      if (bankName != null) return 'Withdrawal of $amountLabel – $bankName';
      return 'ATM Withdrawal $amountLabel';
    }

    // ── 4. Fund Transfer ─────────────────────────────────────────────────
    if (_transferRegex.hasMatch(body)) {
      final transferToRe = RegExp(
        r"\bto\s+(?!(?:your|the|our|my)\b)([A-Za-z][A-Za-z0-9\s&'\-\.]{1,30}?)"
        r"(?=\s*(?:[,.\n]|$|\baccount\b|\ba\/c\b))",
        caseSensitive: false,
      );
      final toMatch = transferToRe.firstMatch(text);
      if (toMatch != null) {
        final recipient = _cleanTitle(toMatch.group(1)!.trim());
        desc = 'Transfer to $recipient $amountLabel';
      } else {
        desc = 'Fund Transfer $amountLabel';
      }
      return _appendBankSuffix(desc, bankName);
    }

    // ── 5. Purchase (explicitly stated) ──────────────────────────────────
    if (_purchaseRegex.hasMatch(body)) {
      final merchant = _extractMerchantAt(text) ?? _extractMerchantFor(text);
      if (merchant != null) {
        desc = 'Purchase at $merchant $amountLabel';
      } else {
        desc = 'Purchase $amountLabel';
      }
      return _appendBankSuffix(desc, bankName);
    }

    // ── 6. Generic: try at / for / from merchant patterns ─────────────────
    final atMerchant = _extractMerchantAt(text);
    if (atMerchant != null) {
      return _appendBankSuffix('Payment at $atMerchant $amountLabel', bankName);
    }

    final forMerchant = _extractMerchantFor(text);
    if (forMerchant != null) {
      return _appendBankSuffix('Payment – $forMerchant $amountLabel', bankName);
    }

    final fromEntity = _extractMerchantFrom(text);
    if (fromEntity != null) {
      return _appendBankSuffix(
          'Received from $fromEntity $amountLabel', bankName);
    }

    // ── 7. Last-resort fallback ───────────────────────────────────────────
    text = text.replaceAll(_debitRegex, '');
    text = text.replaceAll(_creditRegex, '');
    text = text.replaceAll(_noiseWordsRegex, '');
    text = text.replaceAll(RegExp(r"[^A-Za-z0-9\s&'\-]"), ' ');
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    if (text.length > 50) text = text.substring(0, 50).trim();

    final direction = isExpense ? 'Debit' : 'Credit';
    if (text.isNotEmpty) {
      desc = '$direction – ${_cleanTitle(text)} $amountLabel'.trim();
    } else if (bankName != null) {
      return '$direction $amountLabel – $bankName';
    } else {
      return '$direction $amountLabel – $sender';
    }
    return _appendBankSuffix(desc, bankName);
  }

  /// Appends " – {bankName}" to a description when the bank name is known
  /// and not already present in the text.
  static String _appendBankSuffix(String desc, String? bankName) {
    if (bankName == null) return desc;
    if (desc.contains(bankName)) return desc;
    return '$desc – $bankName';
  }

  // ── Entity extraction helpers ────────────────────────────────────────────

  static const _terminators =
      r"(?=\s*(?:[,.\n]|$|\bref\b|\bauth\b|\bavl\b|\bbal\b|\bon\b|\bvia\b|\bif\b|\bfor\b|\bhas\b|\bto\b))";

  static String? _extractMerchantAt(String text) {
    final m = RegExp(
      r"\bat\s+([A-Za-z][A-Za-z0-9\s&'\-\.]{1,35}?)" + _terminators,
      caseSensitive: false,
    ).firstMatch(text);
    if (m == null) return null;
    final candidate = m.group(1)!.trim().replaceAll(RegExp(r'\s{2,}'), ' ');
    return candidate.length >= 2 ? _cleanTitle(candidate) : null;
  }

  static String? _extractMerchantFor(String text) {
    final m = RegExp(
      r"\bfor\s+(?!(?:your|the|our|my|lkr|rs)\b)([A-Za-z][A-Za-z0-9\s&'\-\.]{1,35}?)" +
          _terminators,
      caseSensitive: false,
    ).firstMatch(text);
    if (m == null) return null;
    final candidate = m.group(1)!.trim().replaceAll(RegExp(r'\s{2,}'), ' ');
    return candidate.length >= 2 ? _cleanTitle(candidate) : null;
  }

  static String? _extractMerchantFrom(String text) {
    final m = RegExp(
      r"\bfrom\s+(?!(?:your|the|our|my)\b)([A-Za-z][A-Za-z0-9\s&'\-\.]{1,35}?)" +
          _terminators,
      caseSensitive: false,
    ).firstMatch(text);
    if (m == null) return null;
    final candidate = m.group(1)!.trim().replaceAll(RegExp(r'\s{2,}'), ' ');
    return candidate.length >= 2 ? _cleanTitle(candidate) : null;
  }

  /// Extracts "(From X)" or "From X" at the beginning of a message body.
  static String? _extractBodySender(String body) {
    final bodySenderRe = RegExp(
      r'^\s*\(?[Ff]rom\s+([A-Za-z][A-Za-z0-9\s]{1,20}?)\)?[\s,]',
    );
    final m = bodySenderRe.firstMatch(body);
    if (m != null) return _cleanTitle(m.group(1)!.trim());

    // Also try "Hi [Name], This is [Company]" style — look for known providers
    for (final entry in _senderToBankName.entries) {
      if (body.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Resolves a human-readable bank/institution name from the SMS sender field.
  static String? _getBankName(String sender) {
    for (final entry in _senderToBankName.entries) {
      if (sender.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Formats amount: removes trailing ".00", keeps up to 2 dp, adds commas.
  static String _formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      // Integer — format with thousands comma
      return _addCommas(amount.toInt().toString());
    }
    return _addCommas(amount.toStringAsFixed(2));
  }

  static String _addCommas(String s) {
    // Insert commas from the right for the integer part
    final parts = s.split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    if (parts.length > 1) {
      buffer.write('.');
      buffer.write(parts[1]);
    }
    return buffer.toString();
  }

  /// Title-cases each word; short ALL-CAPS tokens (≤4 chars) are kept as-is
  /// so acronyms like HNB, BOC, ATM survive the transformation.
  static String _cleanTitle(String s) {
    return s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) {
      if (w.length <= 4 &&
          w == w.toUpperCase() &&
          RegExp(r'^[A-Z]+$').hasMatch(w)) {
        return w;
      }
      return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
    }).join(' ');
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
      // Cross-sender dedup: skip if same amount exists within ±5 min
      if (await DatabaseHelper.instance
          .hasCrossSenderDuplicate(t.amount, t.date)) {
        continue;
      }
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
