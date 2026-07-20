class TableNames {
  static const String notes = 'notes';
  static const String tags = 'tags';
  static const String transactions = 'transactions';
  static const String categoryDefinitions = 'category_definitions';
  static const String smsContacts = 'sms_contacts';
  static const String periodLogs = 'period_logs';
  static const String recurringRules = 'recurring_rules';
}

class NoteFields {
  static const String id = 'id';
  static const String title = 'title';
  static const String content = 'content';
  static const String dateCreated = 'dateCreated';
  static const String dateModified = 'dateModified';
  static const String color = 'color';
  static const String isPinned = 'isPinned';
  static const String isArchived = 'isArchived';
  static const String imagePath = 'imagePath';
  static const String category = 'category';
  static const String tags = 'tags';
  static const String previewText = 'previewText';
  static const String deletedAt = 'deletedAt';
  static const String reminderAt = 'reminderAt';
  static const String isLocked = 'isLocked';
}

class RecurringRuleFields {
  static const String id = 'id';
  static const String description = 'description';
  static const String amount = 'amount';
  static const String category = 'category';
  static const String isExpense = 'isExpense';
  static const String frequency = 'frequency'; // daily | weekly | monthly
  static const String nextDue = 'nextDue';
}

class TagFields {
  static const String name = 'name';
  static const String color = 'color';
}

class CategoryFields {
  static const String name = 'name';
  static const String color = 'color';
  static const String keywords = 'keywords';
  static const String isBuiltIn = 'isBuiltIn';
  static const String iconCodePoint = 'iconCodePoint';
}

class SmsContactFields {
  static const String id = 'id';
  static const String senderIds = 'senderIds';
  static const String label = 'label';
  static const String isBuiltIn = 'isBuiltIn';
  static const String isBlocked = 'isBlocked';
}

class PeriodLogFields {
  static const String id = 'id';
  static const String startDate = 'startDate';
  static const String endDate = 'endDate';
  static const String intensity = 'intensity';
  static const String notes = 'notes';
  static const String symptoms = 'symptoms';
}
