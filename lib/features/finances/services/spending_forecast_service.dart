import '../../../../data/transaction_model.dart';

enum SpendingPaceStatus {
  underPace, // 🟢 Well under expected pace
  onTrack,   // 🟡 Spending in line with elapsed month days
  overPace,  // 🟠 Burning faster than day-of-month ratio
  exhausted, // 🔴 Budget fully exceeded
  noBudget,  // ⚪ No category budgets set
}

class CategoryPace {
  final String category;
  final double spent;
  final double budget;
  final double paceRatio; // spent / (budget * elapsedFraction)
  final SpendingPaceStatus status;

  const CategoryPace({
    required this.category,
    required this.spent,
    required this.budget,
    required this.paceRatio,
    required this.status,
  });
}

class MonthlySpendingForecast {
  final double totalBudget;
  final double currentMonthSpent;
  final double remainingBudget;
  final double dailyBurnRate;
  final double projectedMonthEndSpend;
  final double dailySafeToSpend;
  final double elapsedFraction; // currentDay / totalDaysInMonth
  final double budgetSpentFraction; // currentMonthSpent / totalBudget
  final int currentDay;
  final int totalDaysInMonth;
  final int remainingDays;
  final SpendingPaceStatus status;
  final String paceMessage;
  final Map<String, CategoryPace> categoryPaces;

  const MonthlySpendingForecast({
    required this.totalBudget,
    required this.currentMonthSpent,
    required this.remainingBudget,
    required this.dailyBurnRate,
    required this.projectedMonthEndSpend,
    required this.dailySafeToSpend,
    required this.elapsedFraction,
    required this.budgetSpentFraction,
    required this.currentDay,
    required this.totalDaysInMonth,
    required this.remainingDays,
    required this.status,
    required this.paceMessage,
    required this.categoryPaces,
  });
}

class SpendingForecastService {
  SpendingForecastService._();

  static MonthlySpendingForecast calculateMonthlyForecast({
    required List<TransactionModel> transactions,
    required Map<String, double> categoryBudgets,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final year = now.year;
    final month = now.month;
    final currentDay = now.day;

    // Total days in current month
    final firstDayNextMonth = (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    final lastDayThisMonth = firstDayNextMonth.subtract(const Duration(days: 1));
    final totalDaysInMonth = lastDayThisMonth.day;
    final remainingDays = totalDaysInMonth - currentDay + 1;
    final elapsedFraction = (currentDay / totalDaysInMonth).clamp(0.0, 1.0);

    // Sum active category budgets (> 0)
    double totalBudget = 0.0;
    final activeBudgets = <String, double>{};
    for (final entry in categoryBudgets.entries) {
      if (entry.value > 0) {
        totalBudget += entry.value;
        activeBudgets[entry.key] = entry.value;
      }
    }

    // Filter transactions for current month only
    double currentMonthSpent = 0.0;
    final categorySpent = <String, double>{};

    for (final tx in transactions) {
      if (tx.isExpense && tx.date.year == year && tx.date.month == month) {
        currentMonthSpent += tx.amount;
        categorySpent[tx.category] = (categorySpent[tx.category] ?? 0.0) + tx.amount;
      }
    }

    // Calculate historical daily burn rate from prior months for early-month smoothing
    final priorMonthTotals = <String, double>{};
    for (final tx in transactions) {
      if (tx.isExpense && (tx.date.year != year || tx.date.month != month)) {
        final k = '${tx.date.year}-${tx.date.month}';
        priorMonthTotals[k] = (priorMonthTotals[k] ?? 0.0) + tx.amount;
      }
    }
    final double historicalDailyBurn;
    if (priorMonthTotals.isNotEmpty) {
      final totalPrior = priorMonthTotals.values.reduce((a, b) => a + b);
      historicalDailyBurn = totalPrior / (priorMonthTotals.length * 30.4);
    } else {
      historicalDailyBurn = 0.0;
    }

    // Calculate burn rates with adaptive smoothing for days 1–3
    final rawDailyBurnRate = currentDay > 0 ? (currentMonthSpent / currentDay) : 0.0;
    final double dailyBurnRate;
    if (currentDay <= 3 && historicalDailyBurn > 0) {
      final currentWeight = (currentDay / 4.0).clamp(0.2, 0.8);
      dailyBurnRate = (rawDailyBurnRate * currentWeight) +
          (historicalDailyBurn * (1.0 - currentWeight));
    } else {
      dailyBurnRate = rawDailyBurnRate;
    }

    final projectedMonthEndSpend = currentMonthSpent +
        (dailyBurnRate * (totalDaysInMonth - currentDay).clamp(0, totalDaysInMonth));
    final remainingBudget = (totalBudget > 0)
        ? (totalBudget - currentMonthSpent).clamp(0.0, double.infinity)
        : 0.0;

    final double dailySafeToSpend;
    if (totalBudget > 0) {
      if (currentMonthSpent >= totalBudget) {
        dailySafeToSpend = 0.0;
      } else {
        dailySafeToSpend = remainingBudget / (remainingDays > 0 ? remainingDays : 1);
      }
    } else {
      dailySafeToSpend = 0.0;
    }

    final budgetSpentFraction = totalBudget > 0
        ? (currentMonthSpent / totalBudget).clamp(0.0, 2.0)
        : 0.0;

    // Determine status & pace message
    SpendingPaceStatus status;
    String paceMessage;

    if (totalBudget <= 0) {
      status = SpendingPaceStatus.noBudget;
      paceMessage = 'Set category budgets to activate smart daily pace forecasts.';
    } else if (currentMonthSpent >= totalBudget) {
      status = SpendingPaceStatus.exhausted;
      final overBy = (currentMonthSpent - totalBudget);
      paceMessage = 'Monthly budget exceeded by ${overBy.toStringAsFixed(0)} with $remainingDays day${remainingDays == 1 ? '' : 's'} left.';
    } else {
      // Compare budget spent fraction to time elapsed fraction
      final paceRatio = elapsedFraction > 0 ? (budgetSpentFraction / elapsedFraction) : 1.0;

      if (paceRatio <= 0.85) {
        status = SpendingPaceStatus.underPace;
        paceMessage = 'Great job! Spending is well under pace ($remainingDays days remaining).';
      } else if (paceRatio <= 1.10) {
        status = SpendingPaceStatus.onTrack;
        paceMessage = 'On track with current month timeline ($remainingDays days remaining).';
      } else {
        status = SpendingPaceStatus.overPace;
        final projectedOver = (projectedMonthEndSpend - totalBudget);
        paceMessage = 'Pacing fast! At current rate, projected to exceed budget by ${projectedOver.toStringAsFixed(0)}.';
      }
    }

    // Calculate per-category paces
    final categoryPaces = <String, CategoryPace>{};
    for (final cat in {...activeBudgets.keys, ...categorySpent.keys}) {
      final budget = activeBudgets[cat] ?? 0.0;
      final spent = categorySpent[cat] ?? 0.0;

      if (budget <= 0) {
        categoryPaces[cat] = CategoryPace(
          category: cat,
          spent: spent,
          budget: budget,
          paceRatio: 0.0,
          status: SpendingPaceStatus.noBudget,
        );
      } else if (spent >= budget) {
        categoryPaces[cat] = CategoryPace(
          category: cat,
          spent: spent,
          budget: budget,
          paceRatio: spent / budget,
          status: SpendingPaceStatus.exhausted,
        );
      } else {
        final ratio = elapsedFraction > 0 ? (spent / (budget * elapsedFraction)) : 1.0;
        final catStatus = ratio <= 0.85
            ? SpendingPaceStatus.underPace
            : (ratio <= 1.10 ? SpendingPaceStatus.onTrack : SpendingPaceStatus.overPace);

        categoryPaces[cat] = CategoryPace(
          category: cat,
          spent: spent,
          budget: budget,
          paceRatio: ratio,
          status: catStatus,
        );
      }
    }

    return MonthlySpendingForecast(
      totalBudget: totalBudget,
      currentMonthSpent: currentMonthSpent,
      remainingBudget: remainingBudget,
      dailyBurnRate: dailyBurnRate,
      projectedMonthEndSpend: projectedMonthEndSpend,
      dailySafeToSpend: dailySafeToSpend,
      elapsedFraction: elapsedFraction,
      budgetSpentFraction: budgetSpentFraction,
      currentDay: currentDay,
      totalDaysInMonth: totalDaysInMonth,
      remainingDays: remainingDays,
      status: status,
      paceMessage: paceMessage,
      categoryPaces: categoryPaces,
    );
  }
}
