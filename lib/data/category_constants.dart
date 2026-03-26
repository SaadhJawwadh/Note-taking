import 'package:flutter/material.dart';

class CategoryConstants {
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

  static const Map<String, List<String>> keywords = {
    transport: [
      'pickme ride', 'pickme express', 'pickme', 'uber', 'ola', 'taxi', 'cab',
      'bus', 'train', 'tuk', 'fuel', 'petrol', 'toll', 'parking', 'grab'
    ],
    food: [
      'pickme food', 'pickme eats', 'uber eats', 'food delivery', 'kfc',
      'mcd', 'mcdonalds', 'pizza', 'dominos', 'domino', 'café', 'cafe',
      'coffee', 'restaurant', 'groceries', 'grocery', 'food', 'keells',
      'arpico', 'cargills', 'burger', 'noodles', 'rice', 'bakery', 'pastry',
      'icecream', 'sushi', 'biryani', 'kottu', 'supermarket'
    ],
    subscriptions: [
      'amazon prime', 'netflix', 'spotify', 'youtube', 'apple', 'adobe',
      'canva', 'hulu', 'disney', 'microsoft', 'office365', 'chatgpt',
      'openai', 'icloud', 'subscription'
    ],
    shopping: [
      'online shopping', 'amazon', 'daraz', 'kapruka', 'ebay', 'aliexpress',
      'fabric', 'clothing'
    ],
    utilities: [
      'mobile bill', 'phone bill', 'electricity', 'ceb', 'leco', 'water',
      'dialog', 'airtel', 'mobitel', 'slt', 'broadband', 'internet', 'utility'
    ],
    health: [
      'lab test', 'pharmacy', 'hospital', 'doctor', 'medical', 'nawaloka',
      'asiri', 'channel', 'clinic', 'diagnostic', 'medicine'
    ],
    entertainment: [
      'cinema', 'cinemax', 'scope', 'movie', 'concert', 'event', 'ticket'
    ],
    payments: [
      'koko instalment', 'koko installment', 'instalment', 'installment',
      'emi', 'koko', 'loan', 'repayment', 'credit card', 'card payment',
      'hire purchase'
    ],
    deposit: [
      'crm deposit', 'cash deposit', 'deposit', 'credited', 'salary', 'income'
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
}
