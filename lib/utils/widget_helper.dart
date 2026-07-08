import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/transaction_repository.dart';

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

      // Format overview strings
      final spentTodayStr = '$currency ${todaySpent.toStringAsFixed(0)}';
      final spentMonthStr = '$currency ${monthSpent.toStringAsFixed(0)}';
      final incomeMonthStr = '$currency ${monthIncome.toStringAsFixed(0)}';

      // Top 3 recent transactions
      final recentList = activeTx.take(3).map((t) {
        return {
          'category': t.category,
          'description': t.description,
          'amount': '${t.isExpense ? '-' : '+'} $currency ${t.amount.toStringAsFixed(0)}',
          'isExpense': t.isExpense,
        };
      }).toList();

      // Save to shared preferences (Dart SharedPreferences automatically prepends 'flutter.')
      await prefs.setString('widget_spent_today', spentTodayStr);
      await prefs.setString('widget_spent_month', spentMonthStr);
      await prefs.setString('widget_income_month', incomeMonthStr);
      await prefs.setString('widget_recent_transactions', json.encode(recentList));

      // Trigger update on native side
      await _channel.invokeMethod('updateWidget');
    } catch (e) {
      // Avoid crashing the app if widget updates fail
      debugPrint('Widget update failed: $e');
    }
  }
}
