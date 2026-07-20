import 'dart:convert';
import 'database_constants.dart';

class CategoryDefinition {
  final String name;
  final int colorValue; // Color.value integer
  final List<String> keywords;
  final bool isBuiltIn;
  final int? iconCodePoint;

  const CategoryDefinition({
    required this.name,
    required this.colorValue,
    required this.keywords,
    this.isBuiltIn = false,
    this.iconCodePoint,
  });

  Map<String, Object?> toMap() => {
        CategoryFields.name: name,
        CategoryFields.color: colorValue,
        CategoryFields.keywords: jsonEncode(keywords),
        CategoryFields.isBuiltIn: isBuiltIn ? 1 : 0,
        if (iconCodePoint != null) CategoryFields.iconCodePoint: iconCodePoint,
      };

  static CategoryDefinition fromMap(Map<String, Object?> map) {
    final keywordsJson = map[CategoryFields.keywords] as String? ?? '[]';
    final List<dynamic> kList = jsonDecode(keywordsJson);
    return CategoryDefinition(
      name: map[CategoryFields.name] as String,
      colorValue: map[CategoryFields.color] as int,
      keywords: kList.map((e) => e.toString()).toList(),
      isBuiltIn: (map[CategoryFields.isBuiltIn] as int? ?? 0) == 1,
      iconCodePoint: map[CategoryFields.iconCodePoint] as int?,
    );
  }

  CategoryDefinition copyWith({
    String? name,
    int? colorValue,
    List<String>? keywords,
    bool? isBuiltIn,
    int? iconCodePoint,
  }) =>
      CategoryDefinition(
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        keywords: keywords ?? this.keywords,
        isBuiltIn: isBuiltIn ?? this.isBuiltIn,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      );
}
