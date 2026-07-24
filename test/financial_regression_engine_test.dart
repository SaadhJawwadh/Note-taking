import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/services/financial_regression_engine.dart';

void main() {
  group('FinancialRegressionEngine Tests', () {
    test('Empty and single-element lists return safe fallbacks', () {
      final emptyResult = FinancialRegressionEngine.computeForecast([]);
      expect(emptyResult.projectedExpense, equals(0.0));
      expect(emptyResult.rSquared, equals(0.0));

      final singleResult = FinancialRegressionEngine.computeForecast([100.0]);
      expect(singleResult.projectedExpense, equals(100.0));
      expect(singleResult.rSquared, equals(1.0));
    });

    test('Computes trend forecast for standard steady spending', () {
      final expenses = [100.0, 110.0, 120.0, 130.0];
      final result = FinancialRegressionEngine.computeForecast(expenses);

      expect(result.projectedExpense, greaterThan(135.0));
      expect(result.isTrendingUp, isTrue);
      expect(result.rSquared, greaterThan(0.9));
    });

    test('Robust Outlier Filtering dampens single large spending spikes', () {
      // Normal spending ~100k, with one massive 500k spike in month 3
      final expenses = [100000.0, 105000.0, 500000.0, 110000.0, 115000.0];

      final result = FinancialRegressionEngine.computeForecast(
        expenses,
        enableOutlierFiltering: true,
      );

      expect(result.outlierCount, greaterThan(0));
    });

    test('Local self-tuning gamma search executes cleanly', () {
      final expenses = [200000.0, 220000.0, 210000.0, 230000.0, 240000.0];
      final result = FinancialRegressionEngine.computeForecast(expenses);

      expect(result.optimalGamma, greaterThanOrEqualTo(0.70));
      expect(result.optimalGamma, lessThanOrEqualTo(0.95));
    });
  });
}
