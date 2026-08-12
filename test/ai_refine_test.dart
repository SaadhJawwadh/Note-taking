import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:note_taking_app/data/database_helper.dart';
import 'package:note_taking_app/data/transaction_model.dart';
import 'package:note_taking_app/features/finances/data/transaction_repository.dart';
import 'package:note_taking_app/services/sms_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AI Refine Unit Tests', () {
    late Database db;
    late TransactionRepository repo;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 19,
        onCreate: (db, version) async {
          await DatabaseHelper.instance.createTestDatabase(db);
        },
      );
      DatabaseHelper.setMockDatabase(db);
      repo = TransactionRepository.instance;
    });

    tearDown(() async {
      await db.close();
      DatabaseHelper.setMockDatabase(null);
    });

    test('getOriginalSmsBody returns null for transaction without smsId or native permission', () async {
      final txn = TransactionModel(
        amount: 2500,
        description: 'Test Purchase',
        date: DateTime.now(),
      );
      final body = await SmsService.getOriginalSmsBody(txn);
      expect(body, isNull);
    });

    test('performBulkAiRefine handles empty candidate list gracefully', () async {
      final count = await SmsService.performBulkAiRefine(
        lookbackWindow: const Duration(hours: 48),
      );
      expect(count, equals(0));
    });

    test('refineSingleTransactionWithAi falls back gracefully when AI is unsupported', () async {
      final txn = await repo.createTransaction(
        TransactionModel(
          amount: 4500,
          description: 'POS/12345/KEELLS',
          date: DateTime.now(),
          smsId: '9999_1723456789000',
        ),
      );
      final refined = await SmsService.refineSingleTransactionWithAi(txn);
      // Returns null when Gemini Nano AI is unsupported in test environment
      expect(refined, isNull);
    });
  });
}
