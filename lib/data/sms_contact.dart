import 'dart:convert';

class SmsContact {
  final String id;
  final List<String> senderIds;
  final String? label;
  final bool isBuiltIn;
  final bool isBlocked;

  const SmsContact({
    required this.id,
    required this.senderIds,
    this.label,
    this.isBuiltIn = false,
    this.isBlocked = false,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'senderIds': jsonEncode(senderIds),
        'label': label,
        'isBuiltIn': isBuiltIn ? 1 : 0,
        'isBlocked': isBlocked ? 1 : 0,
      };

  static SmsContact fromMap(Map<String, Object?> map) {
    final raw = map['senderIds'] as String? ?? '[]';
    final List<dynamic> list = jsonDecode(raw);
    return SmsContact(
      id: map['id'] as String,
      senderIds: list.map((e) => e.toString()).toList(),
      label: map['label'] as String?,
      isBuiltIn: (map['isBuiltIn'] as int? ?? 0) == 1,
      isBlocked: (map['isBlocked'] as int? ?? 0) == 1,
    );
  }

  SmsContact copyWith({
    String? id,
    List<String>? senderIds,
    String? label,
    bool? isBuiltIn,
    bool? isBlocked,
  }) =>
      SmsContact(
        id: id ?? this.id,
        senderIds: senderIds ?? this.senderIds,
        label: label ?? this.label,
        isBuiltIn: isBuiltIn ?? this.isBuiltIn,
        isBlocked: isBlocked ?? this.isBlocked,
      );
}
