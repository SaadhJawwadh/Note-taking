import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_layout.dart';
import '../../services/financial_regression_engine.dart';

/// A Material 3 Card leveraging [FinancialRegressionEngine] for storage-friendly
/// exponentially-weighted linear regression forecasting and confidence bands.
class FinancialTrendRegressionCard extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;
  final String currency;

  const FinancialTrendRegressionCard({
    super.key,
    required this.monthlyData,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (monthlyData.isEmpty || monthlyData.length < 2) {
      return const SizedBox.shrink();
    }

    final int n = monthlyData.length;
    final expenses = monthlyData
        .map((d) => (d['totalExpense'] as double? ?? 0.0))
        .toList();

    final forecastResult = FinancialRegressionEngine.computeForecast(expenses);

    final monthLabels = monthlyData
        .map((d) => DateFormat.MMM().format(d['month'] as DateTime))
        .toList();

    final numberFormat = NumberFormat('#,##0');

    // Line Spots for actual monthly expense data
    final actualSpots = List.generate(
      n,
      (i) => FlSpot(i.toDouble(), expenses[i]),
    );

    // Compute slope & intercept for plotting the regression line across chart coordinates
    final slope = forecastResult.monthlySlope;
    // Calculate intercept based on actual values
    final intercept = expenses.isNotEmpty ? expenses.first - (slope * 1) : 0.0;

    final regressionSpots = List.generate(
      n + 1,
      (i) => FlSpot(i.toDouble(), max(0.0, (slope * (i + 1)) + intercept)),
    );

    // Compute max Y for chart scaling
    final maxY = expenses
            .fold(forecastResult.upperBound, (a, b) => a > b ? a : b) *
        1.2;

    final isTrendingUp = forecastResult.isTrendingUp;
    final absSlope = slope.abs();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.auto_graph, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Weighted Trend & Forecast',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTrendingUp
                        ? colorScheme.errorContainer
                        : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppLayout.radiusS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTrendingUp ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: isTrendingUp
                            ? colorScheme.onErrorContainer
                            : colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isTrendingUp
                            ? '+$currency ${absSlope.toStringAsFixed(0)}/mo'
                            : '-$currency ${absSlope.toStringAsFixed(0)}/mo',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isTrendingUp
                              ? colorScheme.onErrorContainer
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Predictive Next Month Card Badge with Confidence Interval
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppLayout.radiusM),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.psychology,
                        color: colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Next Month Forecast',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(forecastResult.rSquared * 100).toStringAsFixed(0)}% Fit',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                            if (forecastResult.outlierCount > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '🛡️ Outlier Dampened',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '~$currency ${numberFormat.format(forecastResult.projectedExpense)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Expected Range: $currency ${numberFormat.format(forecastResult.lowerBound)} – $currency ${numberFormat.format(forecastResult.upperBound)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    isTrendingUp ? 'Expense Creep ⚠️' : 'On Track 🟢',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isTrendingUp ? colorScheme.error : colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Regression Chart
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          colorScheme.surfaceContainerHighest,
                      tooltipRoundedRadius: 12,
                      tooltipBorder: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final isActual = spot.barIndex == 0;
                          final label = isActual ? 'Actual' : 'Forecast';
                          final color = isActual
                              ? colorScheme.error
                              : colorScheme.primary;
                          return LineTooltipItem(
                            '$label\n',
                            theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ) ??
                                const TextStyle(),
                            children: [
                              TextSpan(
                                text: '$currency ${numberFormat.format(spot.y)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                  minX: 0,
                  maxX: n.toDouble(),
                  minY: 0,
                  maxY: maxY <= 0 ? 100 : maxY,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx > n) return const SizedBox.shrink();
                          final label = idx < monthLabels.length
                              ? monthLabels[idx]
                              : 'Next';
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: idx == n
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight:
                                    idx == n ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                        reservedSize: 24,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == meta.min) {
                            return const SizedBox.shrink();
                          }
                          final formatted = value >= 1000
                              ? '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K'
                              : value.toStringAsFixed(0);
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              formatted,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // Actual Monthly Expenses Curve
                    LineChartBarData(
                      spots: actualSpots,
                      isCurved: true,
                      color: colorScheme.error,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: colorScheme.error,
                          strokeWidth: 2,
                          strokeColor: colorScheme.surfaceContainerHigh,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.error.withValues(alpha: 0.1),
                      ),
                    ),

                    // Weighted Linear Regression Line Overlay
                    LineChartBarData(
                      spots: regressionSpots,
                      isCurved: false,
                      color: colorScheme.primary,
                      barWidth: 2,
                      dashArray: [6, 4], // Dashed trendline
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          if (index == regressionSpots.length - 1) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: colorScheme.primary,
                              strokeWidth: 2,
                              strokeColor: colorScheme.surfaceContainerHigh,
                            );
                          }
                          return FlDotCirclePainter(radius: 0);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
