import 'package:sqflite_sqlcipher/sqflite.dart';
import '../database_helper.dart';
import '../database_constants.dart';
import '../recurring_rule_model.dart';
import '../transaction_model.dart';
import 'transaction_repository.dart';

class RecurringRuleRepository {
  static final RecurringRuleRepository instance = RecurringRuleRepository._init();
  RecurringRuleRepository._init();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => await _dbHelper.database;

  Future<void> createRule(RecurringRule rule) async {
    final db = await _db;
    await db.insert(TableNames.recurringRules, rule.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<RecurringRule>> readAllRules() async {
    final db = await _db;
    final rows = await db.query(TableNames.recurringRules,
        orderBy: '${RecurringRuleFields.nextDue} ASC');
    return rows.map(RecurringRule.fromJson).toList();
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
