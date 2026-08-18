import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note_taking_app/data/database_helper.dart';
import 'package:note_taking_app/data/period_log_model.dart';
import 'package:note_taking_app/features/health/providers/period_tracker_provider.dart';
import 'package:note_taking_app/services/period_prediction_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 4: Health Tracker & Cycle Regularity Analytics Tests', () {
    late Database testDb;

    setUp(() async {
      testDb = await openDatabase(
        inMemoryDatabasePath,
        version: 19,
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

    test('PeriodPredictionService calculates accurate cycle statistics and regularity scoring', () async {
      // Create 4 consecutive monthly logs with 28-day intervals and 5-day flow duration
      final logs = [
        PeriodLog(
          id: 'log_4',
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2026, 4, 5),
          intensity: 'Medium',
          symptoms: ['Cramps'],
        ),
        PeriodLog(
          id: 'log_3',
          startDate: DateTime(2026, 3, 4), // 28 days prior
          endDate: DateTime(2026, 3, 8),
          intensity: 'Heavy',
          symptoms: ['Bloating', 'Fatigue'],
        ),
        PeriodLog(
          id: 'log_2',
          startDate: DateTime(2026, 2, 4), // 28 days prior
          endDate: DateTime(2026, 2, 8),
          intensity: 'Medium',
          symptoms: [],
        ),
        PeriodLog(
          id: 'log_1',
          startDate: DateTime(2026, 1, 7), // 28 days prior
          endDate: DateTime(2026, 1, 11),
          intensity: 'Light',
          symptoms: [],
        ),
      ];

      final stats = await PeriodPredictionService.calculateCycleStats(logs);

      expect(stats.avgCycleLength, 28);
      expect(stats.avgPeriodDuration, 5);
      expect(stats.regularityScore, greaterThanOrEqualTo(95.0));
      expect(stats.regularityLabel, 'Very Regular');
      expect(stats.variationDays, 0);
      expect(stats.cycleCount, 3);
    });

    test('PeriodTrackerProvider manages logs, overlap guardrails and symptom toggles', () async {
      final provider = PeriodTrackerProvider();
      await provider.loadData();
      expect(provider.logs.isEmpty, isTrue);

      // Create first log
      final log1 = PeriodLog(
        id: 'p1',
        startDate: DateTime.utc(2026, 8, 1),
        endDate: DateTime.utc(2026, 8, 5),
        intensity: 'Medium',
        symptoms: ['Cramps'],
      );
      final created = await provider.createLog(log1);
      expect(created, isTrue);
      expect(provider.logs.length, 1);

      // Attempt overlapping log
      final overlappingLog = PeriodLog(
        id: 'p2',
        startDate: DateTime.utc(2026, 8, 3),
        endDate: DateTime.utc(2026, 8, 7),
        intensity: 'Light',
      );
      final overlapResult = await provider.createLog(overlappingLog);
      expect(overlapResult, isFalse);
      expect(provider.logs.length, 1);

      // Toggle symptom
      await provider.toggleSymptom(provider.logs.first, 'Headache');
      expect(provider.logs.first.symptoms.contains('Headache'), isTrue);

      // Update flow intensity
      await provider.updateIntensity(provider.logs.first, 'Heavy');
      expect(provider.logs.first.intensity, 'Heavy');

      // Delete log
      await provider.deleteLog('p1');
      expect(provider.logs.isEmpty, isTrue);
    });

    test('PeriodTrackerProvider.togglePeriodStatus starts and stops active period', () async {
      final provider = PeriodTrackerProvider();
      await provider.loadData();

      expect(provider.isPeriodActive, isFalse);

      // Start period
      final started = await provider.togglePeriodStatus();
      expect(started, isTrue);
      expect(provider.isPeriodActive, isTrue);
      expect(provider.getCurrentOngoingPeriod(), isNotNull);

      // Stop period
      final stopped = await provider.togglePeriodStatus();
      expect(stopped, isTrue);
      expect(provider.isPeriodActive, isFalse);
      expect(provider.logs.first.endDate, isNotNull);
    });
  });
}
