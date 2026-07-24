import 'dart:math';

/// Immutable container holding detailed predictions from the weighted regression model.
class RegressionForecastResult {
  final double projectedExpense;
  final double lowerBound; // 80% Confidence Interval Lower Limit
  final double upperBound; // 80% Confidence Interval Upper Limit
  final double monthlySlope;
  final bool isTrendingUp;
  final double rSquared; // Model goodness-of-fit coefficient (0.0 to 1.0)
  final int outlierCount; // Number of one-off spending spikes detected & dampened
  final double optimalGamma; // Locally self-tuned decay parameter (e.g. 0.85)
  final Map<String, double> categoryForecasts;

  const RegressionForecastResult({
    required this.projectedExpense,
    required this.lowerBound,
    required this.upperBound,
    required this.monthlySlope,
    required this.isTrendingUp,
    required this.rSquared,
    this.outlierCount = 0,
    this.optimalGamma = 0.85,
    this.categoryForecasts = const {},
  });
}

/// On-device, storage-friendly Exponentially-Weighted Robust Linear Regression Engine.
/// Dynamically self-tunes its recency decay factor (gamma) using local cross-validation
/// over SQLite history, adapting continuously as user transactions grow.
class FinancialRegressionEngine {
  /// Self-tunes the optimal recency decay factor (gamma) via Leave-One-Out validation.
  static double _findOptimalGamma(List<double> expenses) {
    if (expenses.length < 3) return 0.85;

    const candidateGammas = [0.70, 0.75, 0.80, 0.85, 0.90, 0.95];
    double bestGamma = 0.85;
    double minError = double.infinity;

    // Use n-1 months to forecast month n and pick the gamma with lowest absolute error
    final trainExpenses = expenses.sublist(0, expenses.length - 1);
    final targetExpense = expenses.last;

    for (final gamma in candidateGammas) {
      final res = _fitModel(trainExpenses, gamma: gamma, enableOutlierFiltering: false);
      final err = (res.projectedExpense - targetExpense).abs();
      if (err < minError) {
        minError = err;
        bestGamma = gamma;
      }
    }
    return bestGamma;
  }

  /// Internal helper to fit regression with a specific gamma
  static RegressionForecastResult _fitModel(
    List<double> monthlyExpenses, {
    required double gamma,
    required bool enableOutlierFiltering,
  }) {
    final int n = monthlyExpenses.length;
    final double rawMean = monthlyExpenses.reduce((a, b) => a + b) / n;
    final double variance = monthlyExpenses
            .map((y) => pow(y - rawMean, 2))
            .reduce((a, b) => a + b) /
        n;
    final double stdDev = sqrt(variance);

    int outlierCount = 0;
    final weights = <double>[];

    for (int i = 0; i < n; i++) {
      final y = monthlyExpenses[i];
      double w = pow(gamma, n - 1 - i).toDouble();

      if (enableOutlierFiltering && stdDev > 0) {
        final zScore = (y - rawMean).abs() / stdDev;
        if (zScore > 1.8) {
          w *= 0.25;
          outlierCount++;
        }
      }
      weights.add(w);
    }

    double sumW = 0, sumWX = 0, sumWY = 0, sumWXY = 0, sumWX2 = 0;
    for (int i = 0; i < n; i++) {
      final x = (i + 1).toDouble();
      final y = monthlyExpenses[i];
      final w = weights[i];

      sumW += w;
      sumWX += w * x;
      sumWY += w * y;
      sumWXY += w * x * y;
      sumWX2 += w * x * x;
    }

    final denom = (sumW * sumWX2) - (sumWX * sumWX);
    final slope = denom != 0 ? ((sumW * sumWXY) - (sumWX * sumWY)) / denom : 0.0;
    final intercept = (sumWY - (slope * sumWX)) / sumW;

    final rawProjected = (slope * (n + 1)) + intercept;
    final projectedExpense = rawProjected < 0 ? 0.0 : rawProjected;

    final yMean = sumWY / sumW;
    double ssRes = 0, ssTot = 0;

    for (int i = 0; i < n; i++) {
      final x = (i + 1).toDouble();
      final y = monthlyExpenses[i];
      final yHat = (slope * x) + intercept;
      final w = weights[i];

      ssRes += w * pow(y - yHat, 2);
      ssTot += w * pow(y - yMean, 2);
    }

    final rSquared = ssTot > 0 ? max(0.0, min(1.0, 1.0 - (ssRes / ssTot))) : 0.0;
    final stdErr = sqrt(ssRes / (n > 2 ? n - 2 : 1));
    final lowerBound = max(0.0, projectedExpense - (1.28 * stdErr));
    final upperBound = projectedExpense + (1.28 * stdErr);

    return RegressionForecastResult(
      projectedExpense: projectedExpense,
      lowerBound: lowerBound,
      upperBound: upperBound,
      monthlySlope: slope,
      isTrendingUp: slope > 0,
      rSquared: rSquared,
      outlierCount: outlierCount,
      optimalGamma: gamma,
    );
  }

  /// Computes robust weighted linear regression over monthly expense totals.
  /// Automatically self-tunes its recency decay gamma unless custom gamma is supplied.
  static RegressionForecastResult computeForecast(
    List<double> monthlyExpenses, {
    double? gamma,
    bool enableOutlierFiltering = true,
    Map<String, List<double>>? categoryMonthlyExpenses,
  }) {
    if (monthlyExpenses.isEmpty) {
      return const RegressionForecastResult(
        projectedExpense: 0.0,
        lowerBound: 0.0,
        upperBound: 0.0,
        monthlySlope: 0.0,
        isTrendingUp: false,
        rSquared: 0.0,
      );
    }

    if (monthlyExpenses.length < 2) {
      final val = monthlyExpenses.last;
      return RegressionForecastResult(
        projectedExpense: val,
        lowerBound: max(0.0, val * 0.85),
        upperBound: val * 1.15,
        monthlySlope: 0.0,
        isTrendingUp: false,
        rSquared: 1.0,
      );
    }

    // Automatically self-tune recency decay gamma if not explicitly passed
    final effectiveGamma = gamma ?? _findOptimalGamma(monthlyExpenses);

    final res = _fitModel(
      monthlyExpenses,
      gamma: effectiveGamma,
      enableOutlierFiltering: enableOutlierFiltering,
    );

    // Compute category forecasts if category monthly data is provided
    final Map<String, double> categoryForecasts = {};
    if (categoryMonthlyExpenses != null) {
      categoryMonthlyExpenses.forEach((category, catExpenses) {
        if (catExpenses.length >= 2) {
          final catRes = computeForecast(catExpenses, gamma: effectiveGamma);
          categoryForecasts[category] = catRes.projectedExpense;
        } else if (catExpenses.isNotEmpty) {
          categoryForecasts[category] = catExpenses.last;
        }
      });
    }

    return RegressionForecastResult(
      projectedExpense: res.projectedExpense,
      lowerBound: res.lowerBound,
      upperBound: res.upperBound,
      monthlySlope: res.monthlySlope,
      isTrendingUp: res.isTrendingUp,
      rSquared: res.rSquared,
      outlierCount: res.outlierCount,
      optimalGamma: effectiveGamma,
      categoryForecasts: categoryForecasts,
    );
  }
}
