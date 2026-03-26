class TableNames {
  static const String notes = 'notes';
  static const String tags = 'tags';
  static const String transactions = 'transactions';
  static const String categoryDefinitions = 'category_definitions';
  static const String smsContacts = 'sms_contacts';
  static const String periodLogs = 'period_logs';
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
  static const String deletedAt = 'deletedAt';
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
}
