import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note_taking_app/data/database_helper.dart';
import 'package:note_taking_app/services/backup_service.dart';
import 'package:note_taking_app/data/transaction_model.dart';
import 'package:note_taking_app/features/finances/data/transaction_repository.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  test('DatabaseHelper initializes schema and tables cleanly', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await DatabaseHelper.instance.createTestDatabase(db);
    DatabaseHelper.setMockDatabase(db);

    expect(db.isOpen, isTrue);

    final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
    final tableNames = tables.map((t) => t['name'] as String).toList();

    expect(tableNames, contains('notes'));
    expect(tableNames, contains('tags'));
    expect(tableNames, contains('note_tags'));
    expect(tableNames, contains('transactions'));
    expect(tableNames, contains('category_definitions'));
    expect(tableNames, contains('sms_contacts'));
    expect(tableNames, contains('recurring_rules'));
  });

  test('BackupService generateBackupJson works cleanly without column id SQL errors', () async {
    SharedPreferences.setMockInitialValues({});
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await DatabaseHelper.instance.createTestDatabase(db);
    DatabaseHelper.setMockDatabase(db);

    // Create a transaction to verify query execution
    await TransactionRepository.instance.createTransaction(
      TransactionModel(
        amount: 45.50,
        description: 'Test Groceries',
        date: DateTime.now(),
        isExpense: true,
        category: 'Food & Dining',
      ),
    );

    // Call generateBackupJson (this tests the SQL query SELECT * FROM transactions ORDER BY _id ASC)
    final jsonStr = await generateBackupJson();
    expect(jsonStr, isNotEmpty);

    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    expect(decoded.containsKey('notes'), isTrue);
    expect(decoded.containsKey('transactions'), isTrue);
    expect(decoded.containsKey('settings'), isTrue);

    final txList = decoded['transactions'] as List;
    expect(txList.length, equals(1));
    expect(txList.first['amount'], equals(45.50));
    expect(txList.first['description'], equals('Test Groceries'));
  });
}
