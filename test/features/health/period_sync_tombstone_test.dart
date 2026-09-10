import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note_taking_app/data/database_helper.dart';
import 'package:note_taking_app/data/period_log_model.dart';
import 'package:note_taking_app/features/health/data/period_repository.dart';
import 'package:note_taking_app/services/sync_merge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  group('HT-09: Period Log Soft-Delete Tombstones & Sync Parity Tests', () {
    late Database testDb;

    setUp(() async {
      testDb = await openDatabase(
        inMemoryDatabasePath,
        version: 23,
        onCreate: (db, version) async {
          await DatabaseHelper.instance.createTestDatabase(db);
        },
      );
      DatabaseHelper.setMockDatabase(testDb);
    });

    tearDown(() async {
      await testDb.close();
      DatabaseHelper.setMockDatabase(null);
    });

    test('Deleting a period log records tombstone in deleted_period_logs', () async {
      final repo = PeriodRepository.instance;

      final log = PeriodLog(
        id: 'tombstone_test_1',
        startDate: DateTime.utc(2026, 7, 1),
        endDate: DateTime.utc(2026, 7, 5),
        intensity: 'Medium',
      );

      await repo.createPeriodLog(log);
      final readBefore = await repo.readPeriodLog('tombstone_test_1');
      expect(readBefore, isNotNull);

      await repo.deletePeriodLog('tombstone_test_1');
      final readAfter = await repo.readPeriodLog('tombstone_test_1');
      expect(readAfter, isNull);

      final tombstones = await testDb.query('deleted_period_logs', where: 'id = ?', whereArgs: ['tombstone_test_1']);
      expect(tombstones.length, equals(1));
      expect(tombstones.first['id'], equals('tombstone_test_1'));
      expect(tombstones.first['deletedAt'], isNotNull);
    });

    test('SyncMergeService does not resurrect period logs present in tombstones', () async {
      final repo = PeriodRepository.instance;

      // 1. Create and delete locally -> generates tombstone
      final log = PeriodLog(
        id: 'remote_del_1',
        startDate: DateTime.utc(2026, 6, 1),
        endDate: DateTime.utc(2026, 6, 5),
        intensity: 'Light',
      );
      await repo.createPeriodLog(log);
      await repo.deletePeriodLog('remote_del_1');

      // 2. Incoming remote payload has the log that was deleted locally
      final remotePayload = {
        'periodLogs': [log.toMap()],
      };

      await SyncMergeService.instance.mergeRemoteData(remotePayload);

      // 3. Log must NOT be resurrected
      final readAfterMerge = await repo.readPeriodLog('remote_del_1');
      expect(readAfterMerge, isNull);
    });

    test('SyncMergeService applies remote deletedPeriodLogs to delete local logs', () async {
      final repo = PeriodRepository.instance;

      // 1. Local device has an active log
      final log = PeriodLog(
        id: 'peer_deleted_log',
        startDate: DateTime.utc(2026, 5, 1),
        intensity: 'Heavy',
      );
      await repo.createPeriodLog(log);

      // 2. Remote peer deleted it and sends tombstone
      final remotePayload = {
        'deletedPeriodLogs': [
          {'id': 'peer_deleted_log', 'deletedAt': DateTime.now().toIso8601String()}
        ],
      };

      await SyncMergeService.instance.mergeRemoteData(remotePayload);

      // 3. Local log must be deleted and tombstone recorded
      final readAfterMerge = await repo.readPeriodLog('peer_deleted_log');
      expect(readAfterMerge, isNull);

      final localTombstones = await testDb.query('deleted_period_logs', where: 'id = ?', whereArgs: ['peer_deleted_log']);
      expect(localTombstones.length, equals(1));
    });
  });
}
