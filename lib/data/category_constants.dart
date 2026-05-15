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
      'pickme ride', 'pickme express', 'pickme flash', 'pickme', 'uber', 'ola', 'taxi', 'cab',
      'bus', 'train', 'tuk', 'fuel', 'petrol', 'toll', 'parking', 'grab', 'highway', 'expressway'
    ],
    food: [
      'pickme food', 'pickme eats', 'uber eats', 'food delivery', 'kfc',
      'mcd', 'mcdonalds', 'pizza', 'dominos', 'domino', 'café', 'cafe',
      'coffee', 'restaurant', 'groceries', 'grocery', 'food', 'keells',
      'arpico', 'cargills', 'foodcity', 'burger', 'noodles', 'rice', 'bakery', 'pastry',
      'icecream', 'sushi', 'biryani', 'kottu', 'supermarket', 'laughfs', 'glomark', 'spar'
    ],
    subscriptions: [
      'amazon prime', 'netflix', 'spotify', 'youtube', 'apple', 'adobe',
      'canva', 'hulu', 'disney', 'microsoft', 'office365', 'chatgpt',
      'openai', 'icloud', 'subscription', 'patreon', 'github'
    ],
    shopping: [
      'online shopping', 'amazon', 'daraz', 'kapruka', 'ebay', 'aliexpress',
      'fabric', 'clothing', 'fashion', 'shoes', 'apparel', 'mall', 'store'
    ],
    utilities: [
      'mobile bill', 'phone bill', 'electricity', 'ceb', 'leco', 'water', 'nwsdb',
      'dialog', 'airtel', 'mobitel', 'slt', 'hutch', 'broadband', 'internet', 'utility', 'recharge', 'topup', 'reload'
    ],
    health: [
      'lab test', 'pharmacy', 'hospital', 'doctor', 'medical', 'nawaloka',
      'asiri', 'lanka hospitals', 'durdans', 'hemase', 'channel', 'clinic', 'diagnostic', 'medicine', 'health'
    ],
    entertainment: [
      'cinema', 'cinemax', 'scope', 'movie', 'concert', 'event', 'ticket', 'pvr', 'savoy', 'majestic'
    ],
    payments: [
      'koko instalment', 'koko installment', 'instalment', 'installment',
      'emi', 'koko', 'loan', 'repayment', 'credit card', 'card payment',
      'hire purchase', 'mintpay'
    ],
    deposit: [
      'crm deposit', 'cash deposit', 'deposit', 'credited', 'salary', 'income', 'inward remittance', 'interest'
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
