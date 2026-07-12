import 'database_constants.dart';

enum RecurringFrequency {
  daily('daily', 'Daily'),
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly');

  final String value;
  final String label;
  const RecurringFrequency(this.value, this.label);

  static RecurringFrequency fromValue(String value) =>
      RecurringFrequency.values.firstWhere(
        (f) => f.value == value,
        orElse: () => RecurringFrequency.monthly,
      );
}

/// A template that materializes into a real transaction every time its
/// [nextDue] date passes (rent, subscriptions, salary, ...).
class RecurringRule {
  final String id;
  final String description;
  final double amount;
  final String category;
  final bool isExpense;
  final RecurringFrequency frequency;
  final DateTime nextDue;

  const RecurringRule({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.isExpense,
    required this.frequency,
    required this.nextDue,
  });

  RecurringRule copyWith({DateTime? nextDue}) => RecurringRule(
        id: id,
        description: description,
        amount: amount,
        category: category,
        isExpense: isExpense,
        frequency: frequency,
        nextDue: nextDue ?? this.nextDue,
      );

  /// The due date that follows [from], respecting month-length clamping
  /// (a rule due on the 31st fires on the 30th/28th in shorter months).
  DateTime advance(DateTime from) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        final nextMonth = DateTime(from.year, from.month + 1, 1);
        final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        return DateTime(
          nextMonth.year,
          nextMonth.month,
          from.day > lastDay ? lastDay : from.day,
          from.hour,
          from.minute,
        );
    }
  }

  Map<String, Object?> toJson() => {
        RecurringRuleFields.id: id,
        RecurringRuleFields.description: description,
        RecurringRuleFields.amount: amount,
        RecurringRuleFields.category: category,
        RecurringRuleFields.isExpense: isExpense ? 1 : 0,
        RecurringRuleFields.frequency: frequency.value,
        RecurringRuleFields.nextDue: nextDue.toIso8601String(),
      };

  static RecurringRule fromJson(Map<String, Object?> json) => RecurringRule(
        id: json[RecurringRuleFields.id] as String,
        description: (json[RecurringRuleFields.description] as String?) ?? '',
        amount: (json[RecurringRuleFields.amount] as num? ?? 0).toDouble(),
        category: (json[RecurringRuleFields.category] as String?) ?? 'Other',
        isExpense: json[RecurringRuleFields.isExpense] == 1,
        frequency: RecurringFrequency.fromValue(
            (json[RecurringRuleFields.frequency] as String?) ?? 'monthly'),
        nextDue: DateTime.tryParse(
                (json[RecurringRuleFields.nextDue] as String?) ?? '') ??
            DateTime.now(),
      );
}
