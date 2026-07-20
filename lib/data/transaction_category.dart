import 'package:flutter/material.dart';
import 'category_definition.dart';
import 'repositories/transaction_repository.dart';
import 'category_constants.dart';

class TransactionCategory {
  TransactionCategory._();

  static const String other = CategoryConstants.other;
  static const List<String> all = CategoryConstants.all;
  static const Map<String, List<String>> keywords = CategoryConstants.keywords;
  static const Map<String, Color> badgeColors = CategoryConstants.badgeColors;

  static bool _matches(String desc, String kw) {
    return RegExp(r'\b' + RegExp.escape(kw) + r'\b', caseSensitive: false).hasMatch(desc);
  }

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
      if (_matches(desc, kw)) return cat;
    }
    for (final entry in keywords.entries) {
      for (final kw in entry.value) {
        if (!kw.contains(' ') && _matches(desc, kw)) return entry.key;
      }
    }
    return other;
  }

  static List<CategoryDefinition> _cache = [];

  static Future<void> reload() async {
    _cache = await TransactionRepository.instance.getAllCategoryDefinitions();
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
      if (_matches(desc, kw)) return name;
    }
    for (final cat in _cache) {
      for (final kw in cat.keywords) {
        if (!kw.contains(' ') && _matches(desc, kw)) return cat.name;
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

  static const Map<int, IconData> _knownIcons = {
    0xe1d7: Icons.directions_car_outlined,
    0xe56c: Icons.restaurant_outlined,
    0xe616: Icons.subscriptions_outlined,
    0xe59c: Icons.shopping_bag_outlined,
    0xe4e8: Icons.power_outlined,
    0xe3d4: Icons.medical_services_outlined,
    0xe5e7: Icons.sports_esports_outlined,
    0xe472: Icons.payment_outlined,
    0xe57f: Icons.savings_outlined,
    0xe559: Icons.school_outlined,
    0xe295: Icons.flight_outlined,
    0xe318: Icons.home_outlined,
    0xe28a: Icons.fitness_center_outlined,
    0xe38c: Icons.local_grocery_store_outlined,
    0xe14d: Icons.card_giftcard_outlined,
    0xe496: Icons.pets_outlined,
    0xe1b8: Icons.computer_outlined,
    0xe6f2: Icons.work_outlined,
    0xe180: Icons.child_friendly_outlined,
    0xe10a: Icons.build_outlined,
    0xe37d: Icons.local_gas_station_outlined,
    0xe406: Icons.movie_outlined,
    0xe4a1: Icons.phone_android_outlined,
    0xe148: Icons.category_outlined,
  };

  static IconData iconFor(String category) {
    if (_cache.isNotEmpty) {
      for (final def in _cache) {
        if (def.name == category && def.iconCodePoint != null) {
          final known = _knownIcons[def.iconCodePoint!];
          if (known != null) return known;
          return IconData(def.iconCodePoint!, fontFamily: 'MaterialIcons');
        }
      }
    }
    switch (category.toLowerCase()) {
      case 'transport':
      case 'commute':
        return Icons.directions_car_outlined;
      case 'food & dining':
      case 'food':
        return Icons.restaurant_outlined;
      case 'subscriptions':
        return Icons.subscriptions_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'utilities':
      case 'bills':
        return Icons.power_outlined;
      case 'health':
      case 'medical':
        return Icons.medical_services_outlined;
      case 'entertainment':
      case 'leisure':
        return Icons.sports_esports_outlined;
      case 'payments':
      case 'loans':
        return Icons.payment_outlined;
      case 'deposit':
      case 'income':
      case 'salary':
        return Icons.savings_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'travel':
        return Icons.flight_outlined;
      case 'housing':
      case 'home':
        return Icons.home_outlined;
      case 'fitness':
        return Icons.fitness_center_outlined;
      case 'groceries':
        return Icons.local_grocery_store_outlined;
      case 'gifts':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
