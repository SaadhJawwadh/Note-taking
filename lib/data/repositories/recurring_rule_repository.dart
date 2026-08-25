import 'package:sqflite_sqlcipher/sqflite.dart';
import '../database_helper.dart';
import '../database_constants.dart';
import '../recurring_rule_model.dart';
import '../transaction_model.dart';
import '../../features/finances/data/transaction_repository.dart';

class RecurringRuleRepository {
  static final RecurringRuleRepository instance = RecurringRuleRepository._init();
  RecurringRuleRepository._init();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => await _dbHelper.database;

  Future<RecurringRule> createRule(RecurringRule rule) async {
    final db = await _db;
    final allRules = await readAllRules();
    final descLower = rule.description.trim().toLowerCase();
    RecurringRule? existing;
    for (final r in allRules) {
      if (r.description.trim().toLowerCase() == descLower && r.frequency == rule.frequency) {
        existing = r;
        break;
      }
    }

    if (existing != null) {
      final updated = existing.copyWith(
        amount: rule.amount,
        category: rule.category,
        isExpense: rule.isExpense,
        nextDue: rule.nextDue,
      );
      await db.update(
        TableNames.recurringRules,
        updated.toJson(),
        where: '${RecurringRuleFields.id} = ?',
        whereArgs: [updated.id],
      );
      return updated;
    } else {
      await db.insert(
        TableNames.recurringRules,
        rule.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return rule;
    }
  }

  Future<void> updateRule(RecurringRule rule) async {
    final db = await _db;
    await db.update(
      TableNames.recurringRules,
      rule.toJson(),
      where: '${RecurringRuleFields.id} = ?',
      whereArgs: [rule.id],
    );
  }

  Future<List<RecurringRule>> readAllRules() async {
    final db = await _db;
    final rows = await db.query(TableNames.recurringRules,
        orderBy: '${RecurringRuleFields.nextDue} ASC');
    return rows.map(RecurringRule.fromJson).toList();
  }

  Future<RecurringRule?> findMatchingRule({
    required String description,
    required String category,
    required bool isExpense,
    double? amount,
  }) async {
    final allRules = await readAllRules();
    final descLower = description.trim().toLowerCase();
    final catLower = category.trim().toLowerCase();

    for (final rule in allRules) {
      if (rule.isExpense != isExpense) continue;
      final ruleDescLower = rule.description.trim().toLowerCase();
      final ruleCatLower = rule.category.trim().toLowerCase();

      final isExactDesc = ruleDescLower == descLower;
      final isSubstring = descLower.contains(ruleDescLower) || ruleDescLower.contains(descLower);
      final isWordMatch = descLower.split(' ').any((w) => w.length > 3 && ruleDescLower.contains(w));

      if (isExactDesc || (isSubstring && (ruleCatLower == catLower || (amount != null && (rule.amount - amount).abs() < 1.0))) || isWordMatch) {
        return rule;
      }
    }
    return null;
  }

  Future<void> deleteRule(String id) async {
    final db = await _db;
    await db.delete(TableNames.recurringRules,
        where: '${RecurringRuleFields.id} = ?', whereArgs: [id]);
  }

  /// Inserts a real transaction for every period that has elapsed on every
  /// rule, then advances the rule's next-due date. Returns how many
  /// transactions were created. Safe to call on every dashboard refresh.
  Future<int> materializeDueRules() async {
    final now = DateTime.now();
    final rules = await readAllRules();
    var created = 0;

    for (var rule in rules) {
      // Cap the catch-up loop so a rule due years in the past can't flood
      // the ledger in one refresh.
      var iterations = 0;
      var advanced = false;
      while (!rule.nextDue.isAfter(now) && iterations < 36) {
        // Smart cycle-aware deduplication: check if a transaction (manual or SMS)
        // already exists within ±3 days of this due date matching amount & category/description.
        final existingMatch =
            await TransactionRepository.instance.findMatchingRecurringTransaction(
          amount: rule.amount,
          description: rule.description,
          category: rule.category,
          targetDate: rule.nextDue,
          isExpense: rule.isExpense,
          window: const Duration(days: 3),
        );

        if (existingMatch == null) {
          await TransactionRepository.instance.createTransaction(
            TransactionModel(
              amount: rule.amount,
              description: rule.description,
              date: rule.nextDue,
              isExpense: rule.isExpense,
              category: rule.category,
            ),
          );
          created++;
        }
        iterations++;
        rule = rule.copyWith(nextDue: rule.advance(rule.nextDue));
        advanced = true;
      }
      if (advanced) {
        final db = await _db;
        await db.update(
          TableNames.recurringRules,
          {RecurringRuleFields.nextDue: rule.nextDue.toIso8601String()},
          where: '${RecurringRuleFields.id} = ?',
          whereArgs: [rule.id],
        );
      }
    }
    return created;
  }
}
