import '../data/transaction_model.dart';
import '../data/transaction_category.dart';
import 'sms_constants.dart';

class SmsParser {
  static TransactionModel? parseMessage({
    required String body,
    required String address,
    required int? messageId,
    required int? messageDate,
    required Set<String> allowedSenderIds,
    required Set<String> blockedSenderIds,
    required List<String> customExpenseRules,
    required List<String> customIncomeRules,
  }) {
    if (body.trim().isEmpty) return null;

    final isReversal = SmsConstants.reversalRegex.hasMatch(body);
    final isCancellation = SmsConstants.cancellationRegex.hasMatch(body);
    if (isCancellation && !isReversal) return null;

    final senderLower = address.toLowerCase();
    if (blockedSenderIds.any((s) => senderLower.contains(s))) return null;

    final bodyLower = body.toLowerCase();
    final matchesExpenseRule = customExpenseRules.any((r) => bodyLower.contains(r.toLowerCase()));
    final matchesIncomeRule = customIncomeRules.any((r) => bodyLower.contains(r.toLowerCase()));

    final isKnownSender = SmsConstants.bankSenders.any((s) => address.contains(s)) ||
        allowedSenderIds.any((s) => senderLower.contains(s));
    
    final isDebit = matchesExpenseRule || SmsConstants.debitRegex.hasMatch(body);
    final isCredit = matchesIncomeRule || (!matchesExpenseRule && SmsConstants.creditRegex.hasMatch(body));
    final hasInstalment = SmsConstants.instalmentRegex.hasMatch(body);
    final isTransfer = SmsConstants.transferRegex.hasMatch(body);

    if (!isKnownSender && !isDebit && !isCredit && !hasInstalment && !isTransfer) return null;

    if (SmsConstants.dueReminderRegex.hasMatch(body) && !isDebit) return null;
    if (SmsConstants.promotionalRegex.hasMatch(body) && !isDebit && !isCredit && !hasInstalment) return null;

    double? amount;
    var amountMatch = SmsConstants.amountRegex.firstMatch(body);
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
    } else {
      final bareMatch = SmsConstants.bareAmountRegex.firstMatch(body);
      if (bareMatch != null) {
        amount = double.tryParse(bareMatch.group(1)!.replaceAll(',', ''));
      }
    }
    if (amount == null || amount <= 0) return null;

    if (!isReversal && !isDebit && !isCredit && !hasInstalment && !isTransfer) return null;

    final isQPlusTransfer = senderLower.contains('q+') && SmsConstants.transferRegex.hasMatch(body);
    final isExpense = isDebit || hasInstalment || isQPlusTransfer || (!isCredit && !isReversal);

    final description = buildDescription(body, address, amount, isExpense: isExpense);
    final category = isReversal
        ? SmsConstants.reversalSentinel
        : TransactionCategory.fromDescriptionCached('$description $body');

    final date = messageDate != null ? DateTime.fromMillisecondsSinceEpoch(messageDate) : DateTime.now();
    final smsId = messageId != null ? '${messageId}_$messageDate' : 'hash_${body.hashCode}_$messageDate';

    return TransactionModel(
      amount: amount,
      description: description,
      date: date,
      isExpense: isExpense,
      category: category,
      smsId: smsId,
    );
  }

  static String buildDescription(String body, String sender, double amount, {required bool isExpense}) {
    final amountLabel = formatAmount(amount);
    final bankName = getBankName(sender);

    var text = body;
    text = text.replaceAll(SmsConstants.urlRegex, '');
    text = text.replaceAll(SmsConstants.piiBalanceRegex, '');
    text = text.replaceAll(SmsConstants.piiCardRegex, '');
    text = text.replaceAll(SmsConstants.piiRefRegex, '');
    text = text.replaceAll(SmsConstants.piiDateTimePhoneRegex, '');
    text = text.replaceAll(SmsConstants.amountRegex, '');
    text = text.replaceAll(SmsConstants.bareAmountRegex, '');

    if (SmsConstants.depositRegex.hasMatch(body) || SmsConstants.creditRegex.hasMatch(body)) {
      if (bankName != null && !SmsConstants.creditRegex.hasMatch(body)) return 'Deposit of $amountLabel in $bankName';
      final branch = _extractEntity(text, r'\bthrough\s+([A-Za-z][A-Za-z0-9\s\-]{1,25}?)\s+(?:BR|branch)\b') ??
                    _extractEntity(text, r'\bat\s+([A-Za-z][A-Za-z0-9\s\-]{1,35}?)($|\n)');
      if (branch != null) {
        return SmsConstants.creditRegex.hasMatch(body) ? 'Credit of $amountLabel at $branch – ${bankName ?? "Bank"}' : 'Deposit of $amountLabel at $branch';
      }
      return SmsConstants.creditRegex.hasMatch(body) ? 'Credit of $amountLabel${bankName != null ? ' – $bankName' : ''}' : 'Deposit of $amountLabel';
    }

    if (SmsConstants.instalmentRegex.hasMatch(body)) {
      final provider = bankName ?? extractBodySender(body);
      final merchant = _extractEntity(body, r"\bfor\s+(?:your\s+)?([A-Za-z][A-Za-z0-9\s&'\-\.]{1,25}?)\s+(?:order|purchase|plan|account)\b");
      String desc;
      if (provider != null && merchant != null) {
        desc = '$provider Instalment $merchant';
      } else if (provider != null) {
        desc = '$provider Instalment $amountLabel';
      } else if (merchant != null) {
        desc = 'Instalment – $merchant $amountLabel';
      } else {
        desc = 'Instalment $amountLabel';
      }
      return appendBankSuffix(desc, bankName);
    }

    if (SmsConstants.withdrawalRegex.hasMatch(body)) return bankName != null ? 'Withdrawal of $amountLabel – $bankName' : 'ATM Withdrawal $amountLabel';

    if (SmsConstants.transferRegex.hasMatch(body)) {
      final recipient = _extractEntity(text, r"\bto\s+(?!(?:your|the|our|my)\b)([A-Za-z][A-Za-z0-9\s&'\-\.]{1,30}?)(?=\s*(?:[,.\n]|$|\baccount\b|\ba\/c\b))");
      return appendBankSuffix(recipient != null ? 'Transfer to $recipient $amountLabel' : 'Fund Transfer $amountLabel', bankName);
    }

    if (SmsConstants.purchaseRegex.hasMatch(body)) {
      final merchant = extractMerchant(text);
      return appendBankSuffix(merchant != null ? 'Purchase at $merchant $amountLabel' : 'Purchase $amountLabel', bankName);
    }

    final merchant = extractMerchant(text);
    if (merchant != null) return appendBankSuffix('${isExpense ? "Payment at" : "Received from"} $merchant $amountLabel', bankName);

    text = text.replaceAll(SmsConstants.debitRegex, '').replaceAll(SmsConstants.creditRegex, '').replaceAll(SmsConstants.noiseWordsRegex, '').replaceAll(RegExp(r"[^A-Za-z0-9\s&'\-]"), ' ').replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    if (text.length > 50) text = text.substring(0, 50).trim();
    final direction = isExpense ? 'Debit' : 'Credit';
    return appendBankSuffix(text.isNotEmpty ? '$direction – ${cleanTitle(text)} $amountLabel' : '$direction $amountLabel', bankName ?? sender);
  }

  static String? _extractEntity(String text, String pattern) {
    final m = RegExp(pattern, caseSensitive: false).firstMatch(text);
    return m != null ? cleanTitle(m.group(1)!.trim()) : null;
  }

  static String? extractMerchant(String text) {
    const terminators = r"(?=\s*(?:[,.\n]|$|\bref\b|\bauth\b|\bavl\b|\bbal\b|\bon\b|\bvia\b|\bif\b|\bfor\b|\bhas\b|\bto\b))";
    for (final prefix in ['at', 'for', 'from']) {
      final m = RegExp(r"\b" + prefix + r"\s+(?!(?:your|the|our|my|lkr|rs)\b)([A-Za-z][A-Za-z0-9\s&'\-\.]{1,35}?)" + terminators, caseSensitive: false).firstMatch(text);
      if (m != null) {
        final candidate = m.group(1)!.trim().replaceAll(RegExp(r'\s{2,}'), ' ');
        if (candidate.length >= 2) return cleanTitle(candidate);
      }
    }
    return null;
  }

  static String? extractBodySender(String body) {
    final m = RegExp(r'^\s*\(?[Ff]rom\s+([A-Za-z][A-Za-z0-9\s]{1,20}?)\)?[\s,]').firstMatch(body);
    if (m != null) return cleanTitle(m.group(1)!.trim());
    for (final entry in SmsConstants.senderToBankName.entries) {
      if (body.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String? getBankName(String sender) {
    for (final entry in SmsConstants.senderToBankName.entries) {
      if (sender.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String formatAmount(double amount) {
    final s = amount == amount.truncateToDouble() ? amount.toInt().toString() : amount.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    if (parts.length > 1) buffer..write('.')..write(parts[1]);
    return buffer.toString();
  }

  static String cleanTitle(String s) => s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) => (w.length <= 4 && w == w.toUpperCase() && RegExp(r'^[A-Z]+$').hasMatch(w)) ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');

  static String appendBankSuffix(String desc, String? bankName) => (bankName == null || desc.contains(bankName)) ? desc : '$desc – $bankName';
}
