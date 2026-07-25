import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:note_taking_app/data/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
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
}
