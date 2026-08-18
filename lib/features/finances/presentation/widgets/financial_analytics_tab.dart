import 'package:flutter/material.dart';
import '../../../../data/transaction_model.dart';
import '../../../../widgets/finance/financial_category_donut_card.dart';
import '../../../../widgets/finance/financial_trend_regression_card.dart';

/// Modular Analytics Tab widget for FinancialManagerScreen displaying Donut breakdown and Regression Trend analysis.
class FinancialAnalyticsTab extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<Map<String, dynamic>> monthlyData;
  final Map<String, double> categoryExpenses;
  final double totalDateExpense;
  final String currency;
  final VoidCallback onRefresh;

  const FinancialAnalyticsTab({
    super.key,
    required this.transactions,
    required this.monthlyData,
    required this.categoryExpenses,
    required this.totalDateExpense,
    required this.currency,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      final theme = Theme.of(context);
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: theme.colorScheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No analytics data',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Log transactions to see spending analytics & trend predictions.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // 1. Category Expense Donut Breakdown
          if (categoryExpenses.isNotEmpty)
            RepaintBoundary(
              child: FinancialCategoryDonutCard(
                categoryExpenses: categoryExpenses,
                totalExpense: totalDateExpense,
                currency: currency,
              ),
            ),
          const SizedBox(height: 16),

          // 2. Linear Regression Trend & Forecast Card
          RepaintBoundary(
            child: FinancialTrendRegressionCard(
              monthlyData: monthlyData,
              currency: currency,
            ),
          ),
        ]),
      ),
    );
  }
}
