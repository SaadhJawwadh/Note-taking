import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:note_taking_app/data/database_helper.dart';
import 'package:note_taking_app/data/database_constants.dart';
import 'package:note_taking_app/data/category_definition.dart';
import 'package:note_taking_app/data/category_constants.dart';
import 'package:note_taking_app/data/repositories/transaction_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Upgrade & Category Migration Tests', () {
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 16,
          onCreate: (db, version) async {
            // Create v16 schema (without iconCodePoint column)
            await db.execute('''
              CREATE TABLE ${TableNames.categoryDefinitions} (
                ${CategoryFields.name} TEXT PRIMARY KEY,
                ${CategoryFields.color} INTEGER NOT NULL,
                ${CategoryFields.keywords} TEXT NOT NULL DEFAULT '[]',
                ${CategoryFields.isBuiltIn} INTEGER NOT NULL DEFAULT 0
              )
            ''');

            await db.execute('''
              CREATE TABLE ${TableNames.transactions} (
                _id INTEGER PRIMARY KEY AUTOINCREMENT,
                amount REAL NOT NULL,
                description TEXT NOT NULL,
                date TEXT NOT NULL,
                isExpense INTEGER NOT NULL,
                category TEXT NOT NULL DEFAULT 'Other',
                smsId TEXT
              )
            ''');

            await db.execute('''
              CREATE TABLE ${TableNames.recurringRules} (
                ${RecurringRuleFields.id} TEXT PRIMARY KEY,
                ${RecurringRuleFields.description} TEXT NOT NULL,
                ${RecurringRuleFields.amount} REAL NOT NULL,
                ${RecurringRuleFields.category} TEXT NOT NULL,
                ${RecurringRuleFields.isExpense} INTEGER NOT NULL,
                ${RecurringRuleFields.frequency} TEXT NOT NULL,
                ${RecurringRuleFields.nextDue} TEXT NOT NULL
              )
            ''');

            // Insert sample v16 data
            await db.insert(TableNames.categoryDefinitions, {
              CategoryFields.name: 'Dining',
              CategoryFields.color: 0xFFFF9800,
              CategoryFields.keywords: '["food", "lunch"]',
              CategoryFields.isBuiltIn: 1,
            });

            await db.insert(TableNames.transactions, {
              'amount': 25.50,
              'description': 'Lunch Burrito',
              'date': '2026-07-20T12:00:00Z',
              'isExpense': 1,
              'category': 'Dining',
            });

            await db.insert(TableNames.recurringRules, {
              RecurringRuleFields.id: 'rule_1',
              RecurringRuleFields.description: 'Lunch Subs',
              RecurringRuleFields.amount: 15.00,
              RecurringRuleFields.category: 'Dining',
              RecurringRuleFields.isExpense: 1,
              RecurringRuleFields.frequency: 'monthly',
              RecurringRuleFields.nextDue: '2026-08-01',
            });
          },
        ),
      );
    });

    tearDown(() async {
      await db.close();
      DatabaseHelper.setMockDatabase(null);
    });

    test('v16 to v17 migration adds iconCodePoint column cleanly without data loss', () async {
      // Execute v17 upgrade
      await db.execute('ALTER TABLE ${TableNames.categoryDefinitions} ADD COLUMN ${CategoryFields.iconCodePoint} INTEGER');

      // Verify PRAGMA table_info has iconCodePoint
      final tableInfo = await db.rawQuery('PRAGMA table_info(${TableNames.categoryDefinitions})');
      final hasIconCol = tableInfo.any((col) => col['name'] == CategoryFields.iconCodePoint);
      expect(hasIconCol, isTrue);

      // Verify existing transaction data remains intact
      final txs = await db.query(TableNames.transactions);
      expect(txs.length, equals(1));
      expect(txs.first['category'], equals('Dining'));
      expect(txs.first['amount'], equals(25.50));
    });

    test('renameCategoryDefinition updates existing transactions & rules atomically', () async {
      // Execute migration to v17
      await db.execute('ALTER TABLE ${TableNames.categoryDefinitions} ADD COLUMN ${CategoryFields.iconCodePoint} INTEGER');
      DatabaseHelper.setMockDatabase(db);

      const oldDef = CategoryDefinition(
        name: 'Dining',
        colorValue: 0xFFFF9800,
        keywords: ['food'],
        isBuiltIn: true,
      );

      final newDef = oldDef.copyWith(name: 'Food & Restaurants', iconCodePoint: 58136);

      await TransactionRepository.instance.renameCategoryDefinition('Dining', newDef);

      // Verify category definition updated
      final cats = await db.query(TableNames.categoryDefinitions);
      expect(cats.any((c) => c['name'] == 'Food & Restaurants'), isTrue);
      expect(cats.any((c) => c['name'] == 'Dining'), isFalse);

      // Verify transaction updated
      final txs = await db.query(TableNames.transactions);
      expect(txs.first['category'], equals('Food & Restaurants'));

      // Verify recurring rule updated
      final rules = await db.query(TableNames.recurringRules);
      expect(rules.first['category'], equals('Food & Restaurants'));
    });

    test('deleteCategoryDefinition reassigns transactions & rules to Other safely', () async {
      await db.execute('ALTER TABLE ${TableNames.categoryDefinitions} ADD COLUMN ${CategoryFields.iconCodePoint} INTEGER');
      DatabaseHelper.setMockDatabase(db);

      await TransactionRepository.instance.deleteCategoryDefinition('Dining');

      // Verify category definition deleted
      final cats = await db.query(TableNames.categoryDefinitions, where: 'name = ?', whereArgs: ['Dining']);
      expect(cats.isEmpty, isTrue);

      // Verify transaction reassigned to Other
      final txs = await db.query(TableNames.transactions);
      expect(txs.first['category'], equals(CategoryConstants.other));

      // Verify recurring rule reassigned to Other
      final rules = await db.query(TableNames.recurringRules);
      expect(rules.first['category'], equals(CategoryConstants.other));
    });
  });
}
