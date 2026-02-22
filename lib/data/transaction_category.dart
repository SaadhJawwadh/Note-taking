import 'package:flutter/material.dart';

class TransactionCategory {
  TransactionCategory._();

  static const String transport = 'Transport';
  static const String food = 'Food & Dining';
  static const String subscriptions = 'Subscriptions';
  static const String shopping = 'Shopping';
  static const String utilities = 'Utilities';
  static const String health = 'Health';
  static const String entertainment = 'Entertainment';
  static const String other = 'Other';

  static const List<String> all = [
    transport,
    food,
    subscriptions,
    shopping,
    utilities,
    health,
    entertainment,
    other,
  ];

  static const Map<String, List<String>> keywords = {
    transport: [
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
      'netflix',
      'spotify',
      'youtube',
      'apple',
      'amazon prime',
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
      'amazon',
      'daraz',
      'kapruka',
      'ebay',
      'aliexpress',
      'online shopping',
      'fabric',
      'clothing',
    ],
    utilities: [
      'electricity',
      'ceb',
      'leco',
      'water',
      'dialog',
      'airtel',
      'mobitel',
      'slt',
      'mobile bill',
      'broadband',
      'internet',
      'utility',
      'phone bill',
    ],
    health: [
      'pharmacy',
      'hospital',
      'doctor',
      'medical',
      'nawaloka',
      'asiri',
      'channel',
      'clinic',
      'diagnostic',
      'lab test',
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
  };

  static const Map<String, Color> badgeColors = {
    transport: Color(0xFF2196F3),
    food: Color(0xFFFF9800),
    subscriptions: Color(0xFF9C27B0),
    shopping: Color(0xFFE91E63),
    utilities: Color(0xFF607D8B),
    health: Color(0xFF4CAF50),
    entertainment: Color(0xFFFF5722),
    other: Color(0xFF9E9E9E),
  };

  /// Returns the category for a given description string using keyword matching.
  static String fromDescription(String description) {
    final desc = description.toLowerCase();
    for (final entry in keywords.entries) {
      for (final kw in entry.value) {
        if (desc.contains(kw)) return entry.key;
      }
    }
    return other;
  }

  /// Returns the badge color for a category, falling back to grey.
  static Color colorFor(String category) =>
      badgeColors[category] ?? const Color(0xFF9E9E9E);
}
