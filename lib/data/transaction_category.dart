import 'package:flutter/material.dart';
import 'category_definition.dart';
import 'database_helper.dart';

class TransactionCategory {
  TransactionCategory._();

  static const String transport = 'Transport';
  static const String food = 'Food & Dining';
  static const String subscriptions = 'Subscriptions';
  static const String shopping = 'Shopping';
  static const String utilities = 'Utilities';
  static const String health = 'Health';
  static const String entertainment = 'Entertainment';
  static const String payments = 'Payments';
  static const String deposit = 'Deposit';
  static const String other = 'Other';

  static const List<String> all = [
    transport,
    food,
    subscriptions,
    shopping,
    utilities,
    health,
    entertainment,
    payments,
    deposit,
    other,
  ];

  // Compound keywords (multi-word) are listed first within their category for
  // documentation clarity; fromDescription handles them via a two-pass algorithm
  // that checks all compound keywords globally before single keywords.
  static const Map<String, List<String>> keywords = {
    transport: [
      'pickme ride', 'pickme express', // compound — before single 'pickme'
      'pickme',
      'uber',
      'ola',
      'taxi',
      'cab',
      'bus',
      'train',
      'tuk',
      'fuel',
      'petrol',
      'toll',
      'parking',
      'grab',
    ],
    food: [
      'pickme food', 'pickme eats', 'uber eats', 'food delivery', // compound
      'kfc',
      'mcd',
      'mcdonalds',
      'pizza',
      'dominos',
      'domino',
      'café',
      'cafe',
      'coffee',
      'restaurant',
      'groceries',
      'grocery',
      'food',
      'keells',
      'arpico',
      'cargills',
      'burger',
      'noodles',
      'rice',
      'bakery',
      'pastry',
      'icecream',
      'sushi',
      'biryani',
      'kottu',
      'supermarket',
    ],
    subscriptions: [
      'amazon prime', // compound — before 'amazon' in shopping
      'netflix',
      'spotify',
      'youtube',
      'apple',
      'adobe',
      'canva',
      'hulu',
      'disney',
      'microsoft',
      'office365',
      'chatgpt',
      'openai',
      'icloud',
      'subscription',
    ],
    shopping: [
      'online shopping', // compound
      'amazon',
      'daraz',
      'kapruka',
      'ebay',
      'aliexpress',
      'fabric',
      'clothing',
    ],
    utilities: [
      'mobile bill', 'phone bill', // compound
      'electricity',
      'ceb',
      'leco',
      'water',
      'dialog',
      'airtel',
      'mobitel',
      'slt',
      'broadband',
      'internet',
      'utility',
    ],
    health: [
      'lab test', // compound
      'pharmacy',
      'hospital',
      'doctor',
      'medical',
      'nawaloka',
      'asiri',
      'channel',
      'clinic',
      'diagnostic',
      'medicine',
    ],
    entertainment: [
      'cinema',
      'cinemax',
      'scope',
      'movie',
      'concert',
      'event',
      'ticket',
    ],
    payments: [
      'koko instalment', 'koko installment', // compound — before 'koko'
      'instalment',
      'installment',
      'emi',
      'koko',
      'loan',
      'repayment',
      'credit card',
      'card payment',
      'hire purchase',
    ],
    deposit: [
      'crm deposit', 'cash deposit', // compound
      'deposit',
      'credited',
      'salary',
      'income',
    ],
  };

  static const Map<String, Color> badgeColors = {
    transport: Color(0xFF2196F3),
    food: Color(0xFFFF9800),
    subscriptions: Color(0xFF9C27B0),
    shopping: Color(0xFFE91E63),
    utilities: Color(0xFF607D8B),
    health: Color(0xFF4CAF50),
    entertainment: Color(0xFFFF5722),
    payments: Color(0xFF795548),
    deposit: Color(0xFF00897B),
    other: Color(0xFF9E9E9E),
  };

  /// Returns the category for a description using two-pass keyword matching
  /// against the static built-in keyword map.
  ///
  /// **Pass 1** — all compound (multi-word) keywords across every category,
  /// checked in descending length order. This ensures "pickme food" matches
  /// Food & Dining before "pickme" can match Transport.
  ///
  /// **Pass 2** — single keywords in category definition order.
  static String fromDescription(String description) {
    final desc = description.toLowerCase();

    // Pass 1: compound keywords, longest first, across all categories
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

    // Pass 2: single keywords in category order
    for (final entry in keywords.entries) {
      for (final kw in entry.value) {
        if (!kw.contains(' ') && desc.contains(kw)) return entry.key;
      }
    }

    return other;
  }

  // ── Dynamic category cache ────────────────────────────────────────────────

  /// In-memory cache of all category definitions loaded from the database.
  /// Empty until [reload] is called.
  static List<CategoryDefinition> _cache = [];

  /// Loads all category definitions from the database into memory.
  /// Call once at startup and after any category save/delete.
  static Future<void> reload() async {
    _cache = await DatabaseHelper.instance.getAllCategoryDefinitions();
  }

  /// Returns the names of all known categories.
  /// Falls back to the static [all] list if the cache has not been loaded yet.
  static List<String> get allNames =>
      _cache.isNotEmpty ? _cache.map((c) => c.name).toList() : all;

  /// Returns the category for a description using the DB-loaded cache with
  /// two-pass matching. Falls back to [fromDescription] if the cache is empty
  /// (e.g. in background isolates).
  static String fromDescriptionCached(String description) {
    if (_cache.isEmpty) return fromDescription(description);

    final desc = description.toLowerCase();

    // Pass 1: compound keywords (contain space), all categories, longest first
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

    // Pass 2: single keywords in cache order
    for (final cat in _cache) {
      for (final kw in cat.keywords) {
        if (!kw.contains(' ') && desc.contains(kw)) return cat.name;
      }
    }

    return other;
  }

  /// Returns the badge color for a category.
  /// Checks the DB cache first, then the static [badgeColors] map, then grey.
  static Color colorFor(String category) {
    if (_cache.isNotEmpty) {
      for (final def in _cache) {
        if (def.name == category) return Color(def.colorValue);
      }
    }
    return badgeColors[category] ?? const Color(0xFF9E9E9E);
  }
}
