import '../data/database_helper.dart';

class PeriodPredictionService {
  static const int normalCycleLengthDays = 28;
  static const int lutealPhaseLengthDays =
      14; // Typical days from ovulation to next period

  /// Calculates the average cycle length based on the last 3-6 logs.
  /// A cycle is the number of days between the start date of one period and the start date of the next.
  static Future<int> calculateAverageCycleLength() async {
    final logs = await DatabaseHelper.instance.readAllPeriodLogs();

    // Process only logs that have an earlier log to compare against.
    // Since readAllPeriodLogs returns sorted by startDate DESC (newest first).
    if (logs.length < 2) {
      return normalCycleLengthDays;
    }

    int totalDays = 0;
    int cyclesCount = 0;

    // Use up to 6 most recent cycles (which means up to 7 most recent logs)
    final limit = logs.length > 7 ? 7 : logs.length;

    for (int i = 0; i < limit - 1; i++) {
      final currentPeriod = logs[i].startDate;
      final previousPeriod = logs[i + 1].startDate;

      final diff = currentPeriod.difference(previousPeriod).inDays;
      // Filter out unrealistic cycles (e.g. less than 15 days or more than 60 days) to prevent skewed averages
      if (diff >= 15 && diff <= 60) {
        totalDays += diff;
        cyclesCount++;
      }
    }

    if (cyclesCount == 0) {
      return normalCycleLengthDays;
    }

    return (totalDays / cyclesCount).round();
  }

  /// Calculates the estimated start date of the next period based on the most recent log
  /// and the average cycle length.
  static Future<DateTime?> estimateNextPeriod() async {
    final logs = await DatabaseHelper.instance.readAllPeriodLogs();
    if (logs.isEmpty) {
      return null;
    }

    final latestLog = logs.first; // newest first
    final avgCycleLength = await calculateAverageCycleLength();

    return latestLog.startDate.add(Duration(days: avgCycleLength));
  }

  /// Calculates the estimated ovulation date for the *current* cycle
  /// Ovulation typically occurs 14 days before the start of the NEXT period.
  static Future<DateTime?> estimateOvulationDate() async {
    final nextPeriod = await estimateNextPeriod();
    if (nextPeriod == null) return null;

    return nextPeriod.subtract(const Duration(days: lutealPhaseLengthDays));
  }

  /// Returns the number of days until the next predicted period.
  /// Negative means it's overdue.
  static Future<int?> daysUntilNextPeriod() async {
    final nextPeriod = await estimateNextPeriod();
    if (nextPeriod == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextPeriodDay =
        DateTime(nextPeriod.year, nextPeriod.month, nextPeriod.day);

    return nextPeriodDay.difference(today).inDays;
  }
}
