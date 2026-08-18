import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:note_taking_app/data/database_helper.dart';
import 'package:note_taking_app/data/transaction_model.dart';
import 'package:note_taking_app/features/finances/data/transaction_repository.dart';
import 'package:note_taking_app/services/backup_service.dart';
import 'package:note_taking_app/services/sync_merge_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Tombstones & Schema v19 Sync/Backup Tests', () {
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

    test('createTestDatabase creates all v19 tables including deleted_transaction_sms_ids', () async {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table';");
      final tableNames = tables.map((t) => t['name'] as String).toSet();
      expect(tableNames.contains('deleted_transaction_sms_ids'), isTrue);
      expect(tableNames.contains('deleted_notes'), isTrue);
      expect(tableNames.contains('transactions'), isTrue);

      final columns = await db.rawQuery("PRAGMA table_info(transactions);");
      final colNames = columns.map((c) => c['name'] as String).toSet();
      expect(colNames.contains('deletedAt'), isTrue);
    });

    test('generateBackupJson includes deletedTransactionSmsIds in payload', () async {
      await db.insert('deleted_transaction_sms_ids', {
        'smsId': 'sms_tombstone_999',
        'deletedAt': DateTime.now().toIso8601String(),
      });

      final jsonStr = await generateBackupJson();
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(map.containsKey('deletedTransactionSmsIds'), isTrue);
      final tombstones = map['deletedTransactionSmsIds'] as List;
      expect(tombstones.any((t) => t['smsId'] == 'sms_tombstone_999'), isTrue);
    });

    test('restoreBackupFromJson restores deletedTransactionSmsIds to database', () async {
      final backupData = {
        'notes': [],
        'tags': [],
        'noteTags': [],
        'transactions': [],
        'categoryDefinitions': [],
        'smsContacts': [],
        'periodLogs': [],
        'recurringRules': [],
        'deletedNotes': [],
        'deletedTransactionSmsIds': [
          {
            'smsId': 'restored_tombstone_123',
            'deletedAt': DateTime.now().toIso8601String(),
          }
        ],
        'settings': {},
      };

      await BackupService.restoreFromBackupData(backupData);

      final rows = await db.query('deleted_transaction_sms_ids');
      expect(rows.any((r) => r['smsId'] == 'restored_tombstone_123'), isTrue);
    });

    test('SyncMergeService merges remote deletedTransactionSmsIds and purges matching local transactions', () async {
      // 1. Create a local transaction with an smsId
      final txn = await repo.createTransaction(
        TransactionModel(
          amount: 500,
          description: 'Coffee Shop',
          date: DateTime.now(),
          isExpense: true,
          category: 'Food',
          smsId: 'sms_to_be_purged_via_sync',
        ),
      );
      expect(txn.id, isNotNull);

      // Verify it exists locally
      final localBefore = await repo.readAllTransactions();
      expect(localBefore.any((t) => t.smsId == 'sms_to_be_purged_via_sync'), isTrue);

      // 2. Simulate incoming sync from another device containing tombstone for that smsId
      final remoteData = {
        'deletedTransactionSmsIds': [
          {
            'smsId': 'sms_to_be_purged_via_sync',
            'deletedAt': DateTime.now().toIso8601String(),
          }
        ],
        'transactions': [
          {
            'amount': 500.0,
            'description': 'Coffee Shop',
            'date': DateTime.now().toIso8601String(),
            'isExpense': 1,
            'category': 'Food',
            'smsId': 'sms_to_be_purged_via_sync',
          }
        ],
      };

      final result = await SyncMergeService.instance.mergeRemoteData(remoteData);
      expect(result.transactionsMerged, 0); // Should NOT merge because it's tombstoned

      // 3. Verify local transaction was purged and tombstone persisted
      final localAfter = await repo.readAllTransactions();
      expect(localAfter.any((t) => t.smsId == 'sms_to_be_purged_via_sync'), isFalse);

      final tombstoneRows = await db.query('deleted_transaction_sms_ids');
      expect(tombstoneRows.any((r) => r['smsId'] == 'sms_to_be_purged_via_sync'), isTrue);
    });
  });
}
