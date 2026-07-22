import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_layout.dart';

/// A Material 3 Card computing Linear Regression ($y = mx + c$) over 6-month
/// expense data points to plot a trend line and forecast next month's spend.
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

    // Extract monthly expenses for regression computation
    final points = <({double x, double y})>[];
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;
    final int n = monthlyData.length;

    for (int i = 0; i < n; i++) {
      final x = (i + 1).toDouble();
      final y = (monthlyData[i]['totalExpense'] as double? ?? 0.0);
      points.add((x: x, y: y));
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    // Compute Ordinary Least Squares Linear Regression: y = m*x + c
    final denominator = (n * sumX2) - (sumX * sumX);
    final double slope =
        denominator != 0 ? ((n * sumXY) - (sumX * sumY)) / denominator : 0.0;
    final double intercept = (sumY - (slope * sumX)) / n;

    // Projected Next Month Expenditure (x = n + 1)
    final double projectedNextMonth = (slope * (n + 1)) + intercept;
    final double safeProjected = projectedNextMonth < 0 ? 0.0 : projectedNextMonth;

    final monthLabels = monthlyData
        .map((d) => DateFormat.MMM().format(d['month'] as DateTime))
        .toList();

    // Line Spots for actual monthly expense data
    final actualSpots = points.map((p) => FlSpot(p.x - 1, p.y)).toList();

    // Line Spots for regression line from x = 0 to x = n (projected point)
    final regressionSpots = [
      FlSpot(0, (slope * 1) + intercept < 0 ? 0 : (slope * 1) + intercept),
      FlSpot((n - 1).toDouble(), (slope * n) + intercept < 0 ? 0 : (slope * n) + intercept),
      FlSpot(n.toDouble(), safeProjected),
    ];

    // Compute max Y for chart scaling
    final maxY = points.map((p) => p.y).fold(safeProjected, (a, b) => a > b ? a : b) * 1.2;

    final isTrendingUp = slope > 0;
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
                Row(
                  children: [
                    Icon(Icons.auto_graph, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Trend & Forecast',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
                        isTrendingUp
                            ? Icons.trending_up
                            : Icons.trending_down,
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

            // Predictive Next Month Card Badge
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
                        Text(
                          'Next Month Forecast',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '~$currency ${NumberFormat('#,##0').format(safeProjected)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
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
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
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

                    // Linear Regression Line Overlay
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
