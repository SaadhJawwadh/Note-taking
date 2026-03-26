import 'package:flutter/material.dart';
import 'category_definition.dart';
import 'database_helper.dart';
import 'category_constants.dart';

class TransactionCategory {
  TransactionCategory._();

  static const String other = CategoryConstants.other;
  static const List<String> all = CategoryConstants.all;
  static const Map<String, List<String>> keywords = CategoryConstants.keywords;
  static const Map<String, Color> badgeColors = CategoryConstants.badgeColors;

  static String fromDescription(String description) {
    final desc = description.toLowerCase();
    final compounds = <(String, String)>[];
    for (final entry in keywords.entries) {
      for (final kw in entry.value) {
        if (kw.contains(' ')) compounds.add((kw, entry.key));
      }
    }
    compounds.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    for (final (kw, cat) in compounds) {
      if (desc.contains(kw)) return cat;
    }
    for (final entry in keywords.entries) {
      for (final kw in entry.value) {
        if (!kw.contains(' ') && desc.contains(kw)) return entry.key;
      }
    }
    return other;
  }

  static List<CategoryDefinition> _cache = [];

  static Future<void> reload() async {
    _cache = await DatabaseHelper.instance.getAllCategoryDefinitions();
  }

  static List<String> get allNames => _cache.isNotEmpty ? _cache.map((c) => c.name).toList() : all;

  static String fromDescriptionCached(String description) {
    if (_cache.isEmpty) return fromDescription(description);
    final desc = description.toLowerCase();
    final compounds = <(String, String)>[];
    for (final cat in _cache) {
      for (final kw in cat.keywords) {
        if (kw.contains(' ')) compounds.add((kw, cat.name));
      }
    }
    compounds.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    for (final (kw, name) in compounds) {
      if (desc.contains(kw)) return name;
    }
    for (final cat in _cache) {
      for (final kw in cat.keywords) {
        if (!kw.contains(' ') && desc.contains(kw)) return cat.name;
      }
    }
    return other;
  }

  static Color colorFor(String category) {
    if (_cache.isNotEmpty) {
      for (final def in _cache) {
        if (def.name == category) return Color(def.colorValue);
      }
    }
    return badgeColors[category] ?? const Color(0xFF9E9E9E);
  }
}
