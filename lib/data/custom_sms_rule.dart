import 'dart:convert';

enum RuleTransactionType {
  expense,
  income,
  transfer;

  String get label => switch (this) {
        RuleTransactionType.expense => 'Expense',
        RuleTransactionType.income => 'Income',
        RuleTransactionType.transfer => 'Transfer',
      };
}

/// A user-taught parsing rule for incoming bank SMS messages.
class CustomSmsRule {
  final String id;
  final String keyword;
  final RuleTransactionType type;
  final String? category;
  final String? customDescription;
  final bool bypassOtpFilter;
  final bool isEnabled;
  final DateTime createdAt;

  const CustomSmsRule({
    required this.id,
    required this.keyword,
    required this.type,
    this.category,
    this.customDescription,
    this.bypassOtpFilter = false,
    this.isEnabled = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'keyword': keyword,
      'type': type.name,
      'category': category,
      'customDescription': customDescription,
      'bypassOtpFilter': bypassOtpFilter,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomSmsRule.fromMap(Map<String, dynamic> map) {
    return CustomSmsRule(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      keyword: map['keyword'] as String? ?? '',
      type: RuleTransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RuleTransactionType.expense,
      ),
      category: map['category'] as String?,
      customDescription: map['customDescription'] as String?,
      bypassOtpFilter: map['bypassOtpFilter'] as bool? ?? false,
      isEnabled: map['isEnabled'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory CustomSmsRule.fromJson(String source) =>
      CustomSmsRule.fromMap(json.decode(source) as Map<String, dynamic>);

  CustomSmsRule copyWith({
    String? id,
    String? keyword,
    RuleTransactionType? type,
    String? category,
    String? customDescription,
    bool? bypassOtpFilter,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return CustomSmsRule(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      type: type ?? this.type,
      category: category ?? this.category,
      customDescription: customDescription ?? this.customDescription,
      bypassOtpFilter: bypassOtpFilter ?? this.bypassOtpFilter,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomSmsRule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
