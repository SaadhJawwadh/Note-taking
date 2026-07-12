import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/transaction_repository.dart';

/// Workmanager task that recomputes widget data in the background so the
/// TODAY figure rolls over at midnight without the app being opened.
const kWidgetRefreshTaskName = 'com.saadhjawwadh.notebook.widgetRefresh';

class WidgetHelper {
  static const MethodChannel _channel = MethodChannel('com.saadhjawwadh.notebook/widget');

  static Future<void> updateWidgetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currency = prefs.getString('currency') ?? 'LKR';

      final repo = TransactionRepository.instance;
      final allTx = await repo.readAllTransactions();

      // Filter out reversals
      final activeTx = allTx.where((t) => t.category != '__reversal__').toList();

      // Today's total spent
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final todaySpent = activeTx
          .where((t) => t.isExpense && t.date.isAfter(today.subtract(const Duration(seconds: 1))) && t.date.isBefore(tomorrow))
          .fold(0.0, (sum, t) => sum + t.amount);

      // Month's summaries
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);

      final monthTx = activeTx.where((t) => t.date.isAfter(monthStart.subtract(const Duration(seconds: 1))) && t.date.isBefore(monthEnd)).toList();

      final monthSpent = monthTx.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
      final monthIncome = monthTx.where((t) => !t.isExpense).fold(0.0, (sum, t) => sum + t.amount);

      // Format overview strings with thousands separators (LKR 1,250,000)
      final numberFormat = NumberFormat('#,##0');
      final spentTodayStr = '$currency ${numberFormat.format(todaySpent)}';
      final spentMonthStr = '$currency ${numberFormat.format(monthSpent)}';
      final incomeMonthStr = '$currency ${numberFormat.format(monthIncome)}';

      // ── Analytics ──
      // Net cash flow this month
      final net = monthIncome - monthSpent;
      final netStr =
          '${net < 0 ? '-' : '+'}$currency ${numberFormat.format(net.abs())}';

      // Budget progress: total spent vs the sum of all category budgets
      double totalBudget = 0;
      final budgetsStr = prefs.getString('categoryBudgets');
      if (budgetsStr != null) {
        try {
          final Map<String, dynamic> budgets = json.decode(budgetsStr);
          totalBudget =
              budgets.values.fold(0.0, (sum, v) => sum + (v as num).toDouble());
        } catch (_) {}
      }
      final budgetPercent =
          totalBudget > 0 ? ((monthSpent / totalBudget) * 100).round() : -1;
      final budgetLabel = totalBudget > 0
          ? '$currency ${numberFormat.format(monthSpent)} of $currency ${numberFormat.format(totalBudget)}'
          : '';

      // Top spending category this month
      final byCategory = <String, double>{};
      for (final t in monthTx.where((t) => t.isExpense)) {
        byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
      }
      String topCategory = '';
      String topCategoryAmount = '';
      if (byCategory.isNotEmpty) {
        final top =
            byCategory.entries.reduce((a, b) => a.value >= b.value ? a : b);
        topCategory = top.key;
        topCategoryAmount = '$currency ${numberFormat.format(top.value)}';
      }

      // Top 3 recent transactions
      final recentList = activeTx.take(3).map((t) {
        return {
          'category': t.category,
          'description': t.description,
          'amount': '${t.isExpense ? '-' : '+'} $currency ${numberFormat.format(t.amount)}',
          'isExpense': t.isExpense,
        };
      }).toList();

      // Save to shared preferences (Dart SharedPreferences automatically prepends 'flutter.')
      await prefs.setString('widget_spent_today', spentTodayStr);
      await prefs.setString('widget_spent_month', spentMonthStr);
      await prefs.setString('widget_income_month', incomeMonthStr);
      await prefs.setString('widget_net_month', netStr);
      await prefs.setBool('widget_net_positive', net >= 0);
      await prefs.setInt('widget_budget_percent', budgetPercent);
      await prefs.setString('widget_budget_label', budgetLabel);
      await prefs.setString('widget_top_category', topCategory);
      await prefs.setString('widget_top_category_amount', topCategoryAmount);
      await prefs.setString('widget_recent_transactions', json.encode(recentList));

      // Trigger update on native side
      await _channel.invokeMethod('updateWidget');
    } catch (e) {
      // Avoid crashing the app if widget updates fail
      debugPrint('Widget update failed: $e');
    }
  }
}
