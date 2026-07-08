import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note_taking_app/data/database_helper.dart';
import 'package:note_taking_app/data/repositories/transaction_repository.dart';
import 'package:note_taking_app/data/transaction_model.dart';
import 'package:note_taking_app/utils/widget_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup sqflite_common_ffi
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WidgetHelper Unit Tests', () {
    late Database db;
    late TransactionRepository repository;
    final List<MethodCall> methodCalls = [];

    setUp(() async {
      methodCalls.clear();

      // Mock method channel for the widget to verify it triggers updateWidget
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.saadhjawwadh.notebook/widget'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return null;
        },
      );

      // Set mock initial values for SharedPreferences (default currency USD)
      SharedPreferences.setMockInitialValues({
        'flutter.currency': 'USD',
      });

      // Initialize fresh in-memory database
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await DatabaseHelper.instance.createTestDatabase(db);
      DatabaseHelper.setMockDatabase(db);

      repository = TransactionRepository.instance;
    });

    tearDown(() async {
      await db.close();
      DatabaseHelper.setMockDatabase(null);
    });

    test('updateWidgetData correctly calculates summaries and formats preferences', () async {
      final now = DateTime.now();

      // Today expense
      final tx1 = TransactionModel(
        amount: 25.0,
        description: 'Lunch',
        date: now,
        isExpense: true,
        category: 'Food',
      );

      // Today income (should go to income, not today spent)
      final tx2 = TransactionModel(
        amount: 100.0,
        description: 'Part-time job',
        date: now.subtract(const Duration(minutes: 5)),
        isExpense: false,
        category: 'Salary',
      );

      // Past month expense (still this month)
      final tx3 = TransactionModel(
        amount: 50.0,
        description: 'Utility bill',
        date: DateTime(now.year, now.month, 1),
        isExpense: true,
        category: 'Utilities',
      );

      // Reversal Sentinel (should be filtered out entirely)
      final tx4 = TransactionModel(
        amount: 99.0,
        description: 'Reversal item',
        date: now,
        isExpense: true,
        category: '__reversal__',
      );

      // Insert via repository
      await repository.createTransaction(tx1);
      await repository.createTransaction(tx2);
      await repository.createTransaction(tx3);
      await repository.createTransaction(tx4);

      // Call WidgetHelper manually to populate prefs (also triggered by createTransaction)
      await WidgetHelper.updateWidgetData();

      // Verify Shared Preferences
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getString('widget_spent_today'), 'USD 25');
      expect(prefs.getString('widget_spent_month'), 'USD 75'); // 25 (today) + 50 (month start)
      expect(prefs.getString('widget_income_month'), 'USD 100');

      // Verify recent transactions json format
      final recentJson = prefs.getString('widget_recent_transactions');
      expect(recentJson, isNotNull);

      final List<dynamic> recentList = json.decode(recentJson!);
      expect(recentList.length, 3); // Top 3, reversal tx4 is skipped

      // Verify date ordering (newest first, which is DESC)
      final firstTx = recentList[0];
      final secondTx = recentList[1];
      final thirdTx = recentList[2];

      expect(firstTx['description'], 'Lunch');
      expect(secondTx['description'], 'Part-time job');
      expect(thirdTx['description'], 'Utility bill');

      // Verify format matches pattern
      expect(firstTx['amount'], '- USD 25');
      expect(secondTx['amount'], '+ USD 100');
      expect(thirdTx['amount'], '- USD 50');

      // Verify method channel was triggered
      expect(methodCalls.any((call) => call.method == 'updateWidget'), isTrue);
    });
  });
}
