class Note {
  final String id;
  String title;
  String content;
  DateTime dateCreated;
  DateTime dateModified;
  int color;
  bool isPinned;
  bool isArchived;
  String? imagePath;
  String category; // New field
  DateTime? deletedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.dateCreated,
    required this.dateModified,
    this.color = 0xFF252529,
    this.isPinned = false,
    this.isArchived = false,
    this.imagePath,
    this.category = 'All Notes',
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'dateCreated': dateCreated.toIso8601String(),
      'dateModified': dateModified.toIso8601String(),
      'color': color,
      'isPinned': isPinned ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'imagePath': imagePath,
      'category': category,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      dateCreated: DateTime.parse(map['dateCreated']),
      dateModified: DateTime.parse(map['dateModified']),
      color: map['color'],
      isPinned: map['isPinned'] == 1,
      isArchived: (map['isArchived'] ?? 0) == 1,
      imagePath: map['imagePath'],
      category: map['category'] ?? 'All Notes',
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt']) : null,
    );
  }

  Note copyWith({
    String? title,
    String? content,
    DateTime? dateModified,
    int? color,
    bool? isPinned,
    bool? isArchived,
    String? imagePath,
    String? category,
    DateTime? deletedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      dateCreated: dateCreated,
      dateModified: dateModified ?? this.dateModified,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
