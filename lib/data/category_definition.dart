import 'dart:convert';

class CategoryDefinition {
  final String name;
  final int colorValue; // Color.value integer
  final List<String> keywords;
  final bool isBuiltIn;

  const CategoryDefinition({
    required this.name,
    required this.colorValue,
    required this.keywords,
    this.isBuiltIn = false,
  });

  Map<String, Object?> toMap() => {
        'name': name,
        'color': colorValue,
        'keywords': jsonEncode(keywords),
        'isBuiltIn': isBuiltIn ? 1 : 0,
      };

  static CategoryDefinition fromMap(Map<String, Object?> map) {
    final keywordsJson = map['keywords'] as String? ?? '[]';
    final List<dynamic> kList = jsonDecode(keywordsJson);
    return CategoryDefinition(
      name: map['name'] as String,
      colorValue: map['color'] as int,
      keywords: kList.map((e) => e.toString()).toList(),
      isBuiltIn: (map['isBuiltIn'] as int? ?? 0) == 1,
    );
  }

  CategoryDefinition copyWith({
    String? name,
    int? colorValue,
    List<String>? keywords,
    bool? isBuiltIn,
  }) =>
      CategoryDefinition(
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        keywords: keywords ?? this.keywords,
        isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      );
}
