class SmsConstants {
  static const bankSenders = {
    'COMBANK', 'Comm-Bank', 'CBSL', 'ComBank_Q+',
    'PEOBANK', 'PeoplesB', 'PBOCSL', 'PEOPLBK',
    'HNB', 'HNBANK', 'HNBAlerts',
    'SAMPATH', 'Sampath', 'SAMPTBK',
    'BOCCSL', 'BOC', 'BOCSL',
    'NDB', 'NDBBANK',
    'SEYLAN', 'Seybank', 'SEYLNBK',
    'AMANABNK', 'AMANA', 'AMANABK',
    'NTB', 'NTBBANK',
    'LOLC',
  };

  static const senderToBankName = <String, String>{
    'COMBANK': 'Commercial Bank',
    'Comm-Bank': 'Commercial Bank',
    'CBSL': 'Commercial Bank',
    'ComBank_Q+': 'Commercial Bank',
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

  static final amountRegex = RegExp(r'(?:LKR|Rs\.?)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false);
  static final bareAmountRegex = RegExp(r'\bof\s+([\d,]+(?:\.\d{1,2})?)', caseSensitive: false);
  static final depositRegex = RegExp(r'\b(deposit(?:ed)?|crm\s+deposit|cash\s+deposit)\b', caseSensitive: false);
  static final purchaseRegex = RegExp(r'\b(purchase(?:d)?|authorised|authorized)\b', caseSensitive: false);
  static final instalmentRegex = RegExp(r'\b(instalment|installment|emi|monthly\s+payment)\b', caseSensitive: false);
  static final dueReminderRegex = RegExp(r'\b(due\s+tomorrow|due\s+today|due\s+in\s+\d+|payment\s+is\s+due|is\s+due\s+on)\b', caseSensitive: false);
  static final withdrawalRegex = RegExp(r'\b(withdrawn|withdrawal|atm\s+withdrawal|atm\s+debit)\b', caseSensitive: false);
  static final transferRegex = RegExp(r'\b(fund\s+transfer|wire\s+transfer|inter\s+bank\s+transfer|transferred\s+to)\b', caseSensitive: false);
  static final debitRegex = RegExp(r'\b(debit(?:ed)?|withdrawn|withdrawal|spent|charged|purchase(?:d)?|authorised|authorized|payment(?:\s+of)?|deduct(?:ed)?|paid)\b', caseSensitive: false);
  static final creditRegex = RegExp(r'\b(credit(?:ed)?(?!\s+card)|received|deposited|deposit|transferred\s+to\s+you|credited\s+to|salary|payment\s+received|incoming\s+transfer|cash\s+deposit)\b', caseSensitive: false);
  static final reversalRegex = RegExp(r'\b(reversal|reversed|refund(?:ed)?|chargeback|credit\s+back|amount\s+refunded|money\s+returned|returned\s+to\s+your\s+card|reversed\s+back)\b', caseSensitive: false);
  static final cancellationRegex = RegExp(r'\b(cancelled|cancellation|transaction\s+failed|declined|not\s+processed|unsuccessful)\b', caseSensitive: false);
  static final promotionalRegex = RegExp(r'\b(offer|win|congratulations|promo|discount|exclusive|earn\s+\d+\s+points|cashback\s+up\s+to|get\s+\d+%|voucher|reward\s+point)\b', caseSensitive: false);
  
  static final piiCardRegex = RegExp(r'\*\d{4,}|ending\s+[#\*]?\d{4,}|\bno\.?\s*\d{4,}|\ba\/c\s*[\d*x]+|\bxxxx\d{4,}|\b\d{16}\b|\b\d{4,}\*+\d{4,}\b', caseSensitive: false);
  static final piiRefRegex = RegExp(r'\bref(?:\s*no\.?)?\s*:?\s*\w+|\btxn(?:\s*id)?\s*:?\s*[\w\d]+|\bauth(?:\s*code)?\s*:?\s*[\w\d]+|\btran\s*id\s*:?\s*[\w\d]+|\border\s+id\s*:?\s*[\w\d]+|\border\s*#?\s*[\d]+', caseSensitive: false);
  static final piiBalanceRegex = RegExp(r'avl\s*bal[^\d]*[\d,]+(?:\.\d{1,2})?|avail?(?:able)?\s*bal(?:ance)?\s*:?\s*(?:lkr|rs\.?)?\s*[\d,]+(?:\.\d{1,2})?|\bbal\s*:?\s*(?:lkr|rs\.?)?\s*[\d,]+(?:\.\d{1,2})?', caseSensitive: false);
  static final piiDateTimePhoneRegex = RegExp(r'\b\d{1,2}[-/]\d{1,2}[-/]\d{2,4}\b|\b\d{1,2}:\d{2}\s*(?:[ap]m)?\b|\b0\d{9}\b|\b\d{10,11}\b', caseSensitive: false);
  static final urlRegex = RegExp(r'https?://\S+', caseSensitive: false);
  static final noiseWordsRegex = RegExp(r'\b(?:your|has\s+been|dear|valued|customer|card|account|transaction|bank|balance|available|avl|bal|via|the|please|contact|call|if\s+not\s+you|do\s+not\s+share|cardholder)\b', caseSensitive: false);

  static const reversalSentinel = '__reversal__';
}
