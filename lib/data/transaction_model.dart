import 'transaction_category.dart';

class TransactionModel {
  final int? id;
  final double amount;
  final String description;
  final DateTime date;
  final bool isExpense;
  final String category;
  final String? smsId;

  TransactionModel({
    this.id,
    required this.amount,
    required this.description,
    required this.date,
    this.isExpense = true,
    this.category = TransactionCategory.other,
    this.smsId,
  });

  TransactionModel copy({
    int? id,
    double? amount,
    String? description,
    DateTime? date,
    bool? isExpense,
    String? category,
    String? smsId,
  }) =>
      TransactionModel(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        description: description ?? this.description,
        date: date ?? this.date,
        isExpense: isExpense ?? this.isExpense,
        category: category ?? this.category,
        smsId: smsId ?? this.smsId,
      );

  static TransactionModel fromJson(Map<String, Object?> json) =>
      TransactionModel(
        id: json[TransactionFields.id] as int?,
        amount: json[TransactionFields.amount] as double,
        description: json[TransactionFields.description] as String,
        date: DateTime.parse(json[TransactionFields.date] as String),
        isExpense: (json[TransactionFields.isExpense] as int) == 1,
        category: (json[TransactionFields.category] as String?) ??
            TransactionCategory.other,
        smsId: json[TransactionFields.smsId] as String?,
      );

  Map<String, Object?> toJson() => {
        TransactionFields.id: id,
        TransactionFields.amount: amount,
        TransactionFields.description: description,
        TransactionFields.date: date.toIso8601String(),
        TransactionFields.isExpense: isExpense ? 1 : 0,
        TransactionFields.category: category,
        TransactionFields.smsId: smsId,
      };
}

class TransactionFields {
  static final List<String> values = [
    id,
    amount,
    description,
    date,
    isExpense,
    category,
    smsId,
  ];

  static const String id = '_id';
  static const String amount = 'amount';
  static const String description = 'description';
  static const String date = 'date';
  static const String isExpense = 'isExpense';
  static const String category = 'category';
  static const String smsId = 'smsId';
}
