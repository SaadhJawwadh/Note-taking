import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note_taking_app/data/database_helper.dart';
import 'package:note_taking_app/data/period_log_model.dart';
import 'package:note_taking_app/features/health/providers/period_tracker_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  group('HT-01: Dynamic Cycle Phase Calculation & Overdue Modulo Safeguard Tests', () {
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

    test('Overdue cycle does NOT modulo reset back to Day 1-5 Menstrual Phase', () async {
      final provider = PeriodTrackerProvider();

      // Today minus 34 days with a 28-day cycle -> 6 days overdue
      final now = DateTime.now();
      final startDate = DateTime.utc(now.year, now.month, now.day).subtract(const Duration(days: 34));

      final log = PeriodLog(
        id: 'overdue_log_1',
        startDate: startDate,
        endDate: startDate.add(const Duration(days: 4)),
        intensity: 'Medium',
      );

      await provider.createLog(log);
      await provider.loadData(showLoading: false);

      expect(provider.currentCycleDay, equals(35));
      expect(provider.currentPhase, equals('Late / Overdue'));
      expect(provider.phaseDescription, contains('Delayed by 7 days'));
    });

    test('Future start date gracefully clamps to Day 1 Menstrual Phase without exception', () async {
      final provider = PeriodTrackerProvider();

      final now = DateTime.now();
      final futureDate = DateTime.utc(now.year, now.month, now.day).add(const Duration(days: 2));

      final log = PeriodLog(
        id: 'future_log_1',
        startDate: futureDate,
        intensity: 'Light',
      );

      await provider.createLog(log);
      await provider.loadData(showLoading: false);

      expect(provider.currentCycleDay, equals(1));
      expect(provider.currentPhase, equals('Menstrual Phase'));
    });

    test('Cycle phase reflects active follicular and ovulatory window dynamically', () async {
      final provider = PeriodTrackerProvider();

      final now = DateTime.now();
      // Day 14 of 28 day cycle -> Ovulatory Phase
      final startDate = DateTime.utc(now.year, now.month, now.day).subtract(const Duration(days: 13));

      final log = PeriodLog(
        id: 'ovulatory_log_1',
        startDate: startDate,
        endDate: startDate.add(const Duration(days: 4)),
        intensity: 'Medium',
      );

      await provider.createLog(log);
      await provider.loadData(showLoading: false);

      expect(provider.currentCycleDay, equals(14));
      expect(provider.currentPhase, equals('Ovulatory Phase'));
    });
  });
}
