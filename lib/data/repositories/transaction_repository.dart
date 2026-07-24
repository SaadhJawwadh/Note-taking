import 'dart:convert';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../database_helper.dart';
import '../database_seed.dart';
import '../category_constants.dart';
import '../transaction_model.dart';
import '../database_constants.dart';
import '../category_definition.dart';
import '../sms_contact.dart';
import '../../utils/widget_helper.dart';

class TransactionRepository {
  static final TransactionRepository instance = TransactionRepository._init();
  TransactionRepository._init();
  factory TransactionRepository() => instance;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => await _dbHelper.database;

  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final db = await _db;
    final id = await db.insert(TableNames.transactions, transaction.toJson());
    final result = transaction.copy(id: id);
    await WidgetHelper.updateWidgetData();
    return result;
  }

  Future<TransactionModel?> createSmsTransaction(TransactionModel transaction) async {
    final db = await _db;
    final id = await db.insert(TableNames.transactions, transaction.toJson(), conflictAlgorithm: ConflictAlgorithm.ignore);
    if (id > 0) {
      final result = transaction.copy(id: id);
      await WidgetHelper.updateWidgetData();
      return result;
    }
    return null;
  }

  Future<TransactionModel?> readTransaction(int id) async {
    final db = await _db;
    final maps = await db.query(TableNames.transactions, columns: TransactionFields.values, where: '${TransactionFields.id} = ?', whereArgs: [id]);
    return maps.isNotEmpty ? TransactionModel.fromJson(maps.first) : null;
  }

  Future<List<TransactionModel>> readAllTransactions() async {
    final db = await _db;
    final result = await db.query(TableNames.transactions, orderBy: '${TransactionFields.date} DESC');
    return result.map((json) => TransactionModel.fromJson(json)).toList();
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await _db;
    final count = await db.update(TableNames.transactions, transaction.toJson(), where: '${TransactionFields.id} = ?', whereArgs: [transaction.id]);
    if (count > 0) {
      await WidgetHelper.updateWidgetData();
    }
    return count;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await _db;
    final count = await db.delete(TableNames.transactions, where: '${TransactionFields.id} = ?', whereArgs: [id]);
    if (count > 0) {
      await WidgetHelper.updateWidgetData();
    }
    return count;
  }

  Future<List<TransactionModel>> searchTransactions(String keyword) async {
    final db = await _db;
    final result = await db.query(TableNames.transactions, where: 'description LIKE ? OR category LIKE ?', whereArgs: ['%$keyword%', '%$keyword%'], orderBy: 'date DESC');
    return result.map((json) => TransactionModel.fromJson(json)).toList();
  }

  Future<TransactionModel?> findReversalTarget(double amount, DateTime date, {int windowDays = 7}) async {
    final db = await _db;
    final windowStart = date.subtract(Duration(days: windowDays)).toIso8601String();
    final windowEnd = date.toIso8601String();
    final rows = await db.query(TableNames.transactions, where: 'amount = ? AND isExpense = 1 AND smsId IS NOT NULL AND date >= ? AND date <= ?', whereArgs: [amount, windowStart, windowEnd], orderBy: '${TransactionFields.date} DESC', limit: 1);
    return rows.isNotEmpty ? TransactionModel.fromJson(rows.first) : null;
  }

  Future<bool> smsExists(String smsId) async {
    final db = await _db;
    final result = await db.query(TableNames.transactions, columns: [TransactionFields.id], where: '${TransactionFields.smsId} = ?', whereArgs: [smsId], limit: 1);
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getMonthlyTransactionSummary(int months) async {
    final db = await _db;
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (int i = months - 1; i >= 0; i--) {
      final periodStart = DateTime(now.year, now.month - i, 1);
      final periodEnd = DateTime(now.year, now.month - i + 1, 1);
      final rows = await db.rawQuery(
          'SELECT SUM(CASE WHEN isExpense = 0 THEN amount ELSE 0.0 END) AS totalIncome, '
          'SUM(CASE WHEN isExpense = 1 THEN amount ELSE 0.0 END) AS totalExpense '
          'FROM ${TableNames.transactions} '
          'WHERE date >= ? AND date < ? AND category != ?',
          [
            periodStart.toIso8601String(),
            periodEnd.toIso8601String(),
            '__reversal__'
          ]);
      result.add({
        'month': periodStart,
        'totalIncome': (rows.first['totalIncome'] as num?)?.toDouble() ?? 0.0,
        'totalExpense': (rows.first['totalExpense'] as num?)?.toDouble() ?? 0.0
      });
    }
    return result;
  }

  Future<Map<String, double>> getAllTimeSummary() async {
    final db = await _db;
    final rows = await db.rawQuery(
        'SELECT SUM(CASE WHEN isExpense = 0 THEN amount ELSE 0.0 END) AS totalIncome, '
        'SUM(CASE WHEN isExpense = 1 THEN amount ELSE 0.0 END) AS totalExpense '
        'FROM ${TableNames.transactions} '
        'WHERE category != ?',
        ['__reversal__']);
    return {
      'totalIncome': (rows.first['totalIncome'] as num?)?.toDouble() ?? 0.0,
      'totalExpense': (rows.first['totalExpense'] as num?)?.toDouble() ?? 0.0
    };
  }

  // Category Definition CRUD
  /// Deletes every category definition (built-in and custom) and re-seeds
  /// the built-in set with default colors and keywords. Existing
  /// transactions keep their category labels.
  Future<void> resetCategoriesToDefaults() async {
    final db = await _db;
    await db.delete(TableNames.categoryDefinitions);
    await DatabaseSeed.seedBuiltInCategories(db);
  }

  /// Restores the default keyword lists on built-in categories without
  /// touching custom categories.
  Future<void> resetBuiltInCategoryKeywords() async {
    final db = await _db;
    for (final name in CategoryConstants.all) {
      final kws = CategoryConstants.keywords[name] ?? <String>[];
      await db.update(
        TableNames.categoryDefinitions,
        {CategoryFields.keywords: jsonEncode(kws)},
        where: '${CategoryFields.name} = ? AND ${CategoryFields.isBuiltIn} = 1',
        whereArgs: [name],
      );
    }
  }

  Future<List<CategoryDefinition>> getAllCategoryDefinitions() async {
    final db = await _db;
    final rows = await db.query(TableNames.categoryDefinitions, orderBy: '${CategoryFields.isBuiltIn} DESC, ${CategoryFields.name} ASC');
    return rows.map(CategoryDefinition.fromMap).toList();
  }

  Future<void> upsertCategoryDefinition(CategoryDefinition def) async {
    await renameCategoryDefinition(def.name, def);
  }

  Future<void> renameCategoryDefinition(String oldName, CategoryDefinition newDef) async {
    final db = await _db;
    await db.transaction((txn) async {
      if (oldName != newDef.name) {
        await txn.update(
          TableNames.transactions,
          {TransactionFields.category: newDef.name},
          where: '${TransactionFields.category} = ?',
          whereArgs: [oldName],
        );
        await txn.update(
          TableNames.recurringRules,
          {RecurringRuleFields.category: newDef.name},
          where: '${RecurringRuleFields.category} = ?',
          whereArgs: [oldName],
        );
        await txn.delete(
          TableNames.categoryDefinitions,
          where: '${CategoryFields.name} = ?',
          whereArgs: [oldName],
        );
      }
      await txn.insert(
        TableNames.categoryDefinitions,
        newDef.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> deleteCategoryDefinition(String name) async {
    if (name == CategoryConstants.other) return;
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        TableNames.transactions,
        {TransactionFields.category: CategoryConstants.other},
        where: '${TransactionFields.category} = ?',
        whereArgs: [name],
      );
      await txn.update(
        TableNames.recurringRules,
        {RecurringRuleFields.category: CategoryConstants.other},
        where: '${RecurringRuleFields.category} = ?',
        whereArgs: [name],
      );
      await txn.delete(
        TableNames.categoryDefinitions,
        where: '${CategoryFields.name} = ?',
        whereArgs: [name],
      );
    });
  }

  // SMS Contacts CRUD
  Future<List<SmsContact>> getAllSmsContacts() async {
    final db = await _db;
    final rows = await db.query(TableNames.smsContacts, orderBy: '${SmsContactFields.isBuiltIn} DESC, ${SmsContactFields.label} ASC, ${SmsContactFields.id} ASC');
    return rows.map(SmsContact.fromMap).toList();
  }

  Future<void> upsertSmsContact(SmsContact contact) async {
    final db = await _db;
    await db.insert(TableNames.smsContacts, contact.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSmsContact(String id) async {
    final db = await _db;
    await db.delete(TableNames.smsContacts, where: '${SmsContactFields.id} = ? AND ${SmsContactFields.isBuiltIn} = 0', whereArgs: [id]);
  }

  Future<void> setSmsContactBlocked(String id, bool blocked) async {
    final db = await _db;
    await db.update(TableNames.smsContacts, {SmsContactFields.isBlocked: blocked ? 1 : 0}, where: '${SmsContactFields.id} = ?', whereArgs: [id]);
  }

  Future<bool> hasCrossSenderDuplicate(double amount, DateTime date) async {
    final db = await _db;
    final windowStart = date.subtract(const Duration(minutes: 5)).toIso8601String();
    final windowEnd = date.add(const Duration(minutes: 5)).toIso8601String();
    final rows = await db.query(
      TableNames.transactions,
      columns: [TransactionFields.id],
      where: 'amount >= ? AND amount <= ? AND smsId IS NOT NULL AND date >= ? AND date <= ?',
      whereArgs: [amount - 0.005, amount + 0.005, windowStart, windowEnd],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Scans SQLite database for duplicate transaction rows with matching amount,
  /// isExpense, and timestamp window, purging redundant duplicates and
  /// returning the count of removed items.
  Future<int> cleanupDuplicates() async {
    final db = await _db;
    final allTxns = await readAllTransactions();
    if (allTxns.length < 2) return 0;

    final toDeleteIds = <int>{};
    for (int i = 0; i < allTxns.length; i++) {
      final a = allTxns[i];
      if (a.id == null || toDeleteIds.contains(a.id)) continue;

      for (int j = i + 1; j < allTxns.length; j++) {
        final b = allTxns[j];
        if (b.id == null || toDeleteIds.contains(b.id)) continue;

        final isSameAmount = (a.amount - b.amount).abs() < 0.01;
        final isSameType = a.isExpense == b.isExpense;
        final isTimeClose = a.date.difference(b.date).abs() <= const Duration(seconds: 120);

        if (isSameAmount && isSameType && isTimeClose) {
          toDeleteIds.add(b.id!);
        }
      }
    }

    if (toDeleteIds.isNotEmpty) {
      final placeholders = List.filled(toDeleteIds.length, '?').join(',');
      await db.delete(
        TableNames.transactions,
        where: '${TransactionFields.id} IN ($placeholders)',
        whereArgs: toDeleteIds.toList(),
      );
      await WidgetHelper.updateWidgetData();
    }

    return toDeleteIds.length;
  }
}
