import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../data/transaction_model.dart';
import '../../../../screens/app_lock_screen.dart';
import '../../../../core/ui/app_bottom_sheet.dart';

/// Service for exporting financial transaction ledgers to CSV formats with built-in AI analysis prompts.
class FinancialExportService {
  FinancialExportService._();

  /// Default financial analysis system prompt optimized for LLMs (Claude, ChatGPT, Gemini, NotebookLM).
  static String buildAiAnalysisPrompt({
    required int transactionCount,
    required String currency,
    DateTimeRange? dateRange,
  }) {
    final rangeText = dateRange != null
        ? 'spanning ${DateFormat('yyyy-MM-dd').format(dateRange.start)} to ${DateFormat('yyyy-MM-dd').format(dateRange.end)}'
        : 'from my complete transaction ledger';

    return '''
# AI Financial Health & Spending Habits Analysis Prompt

Act as my expert personal financial advisor and spending habit analyst.
I have attached my raw financial transactions CSV ($transactionCount records in $currency, $rangeText).

Please conduct an in-depth financial analysis and provide a structured report covering:

1. 📊 **Executive Financial Overview**:
   - Total Income, Total Expenses, Net Cash Flow, and Overall Savings Rate (%).
   - Monthly average burn rate and income vs. expense balance.

2. 🏷️ **Category & Habit Breakdown (50/30/20 Rule)**:
   - Categorize spending into Needs (essentials), Wants (discretionary), and Savings/Investments.
   - Highlight the top 5 expense categories with total amounts and percentage of total spend.

3. 🔁 **Recurring Subscriptions & Fixed Leaks**:
   - Detect recurring payments (streaming, gym, utilities, recurring digital subscriptions).
   - Flag any forgotten, duplicated, or creeping recurring subscriptions.

4. 🔍 **Top Merchant Drains & Outliers**:
   - Identify merchants with highest cumulative spend.
   - Detect unusual single transaction spikes or impulsive weekend clusters.

5. 💡 **3 High-Impact Actionable Recommendations**:
   - Concrete, realistic suggestions to cut discretionary leaks and boost monthly savings by at least 10–15%.

Please format your response using clean Markdown with tables, bullet points, and actionable takeaways.
'''.trim();
  }

  /// Converts a list of [TransactionModel] records into standard RFC 4180 CSV format.
  /// When [includeAiPreamble] is true, adds commented header lines (`#`) describing the dataset for LLM ingestion.
  static String generateCsv(
    List<TransactionModel> transactions, {
    String currency = 'Rs.',
    bool includeAiPreamble = false,
  }) {
    final buffer = StringBuffer();

    if (includeAiPreamble) {
      buffer.writeln('# Everything App Financial Ledger Export');
      buffer.writeln('# Currency: $currency | Total Records: ${transactions.length} | Export Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
      buffer.writeln('# Format: Date(YYYY-MM-DD), Time(HH:MM:SS), Description, Category, Type(Expense/Income), Amount, Currency, SMS_ID');
      buffer.writeln('# AI Instructions: Parse this table to evaluate cash flow, spending habits, recurring subscriptions, and savings potential.');
      buffer.writeln('# --------------------------------------------------------------------------------');
    }

    // CSV Header
    buffer.writeln('Date,Time,Description,Category,Account,Type,Amount,Currency,SMS_ID');

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm:ss');

    for (final tx in transactions) {
      final dateStr = dateFormat.format(tx.date);
      final timeStr = timeFormat.format(tx.date);
      final escapedDesc = _escapeCsvField(tx.description);
      final escapedCategory = _escapeCsvField(tx.category);
      final accountStr = tx.account == AccountType.savings ? 'Savings' : 'Daily';
      final typeStr = tx.isExpense ? 'Expense' : 'Income';
      final amountStr = tx.amount.toStringAsFixed(2);
      final escapedCurrency = _escapeCsvField(currency);
      final smsIdStr = tx.smsId ?? '';

      buffer.writeln('$dateStr,$timeStr,$escapedDesc,$escapedCategory,$accountStr,$typeStr,$amountStr,$escapedCurrency,$smsIdStr');
    }

    return buffer.toString();
  }

  /// Escapes a CSV field according to RFC 4180 rules (quotes strings with commas, quotes, or newlines).
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }

  /// Shares a list of transactions as an exported `.csv` file via the system share sheet,
  /// pre-filling the share text with the AI spending habits analysis prompt.
  static Future<void> shareTransactionsCsv(
    List<TransactionModel> transactions, {
    String currency = 'Rs.',
    String filePrefix = 'transactions_export',
    bool includeAiPrompt = true,
  }) async {
    final csvContent = generateCsv(
      transactions,
      currency: currency,
      includeAiPreamble: includeAiPrompt,
    );
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${tempDir.path}/${filePrefix}_$timestamp.csv');
    await file.writeAsString(csvContent);

    final promptText = includeAiPrompt
        ? buildAiAnalysisPrompt(
            transactionCount: transactions.length,
            currency: currency,
          )
        : 'Exported ${transactions.length} transactions ($currency)';

    AppLockScreen.ignoreNextResumeLock();
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: promptText,
      subject: 'Financial Ledger & AI Spending Analysis Export',
    );
  }

  /// Displays an M3 bottom sheet modal with AI Prompt export and copy options.
  static void showExportSheet(
    BuildContext context,
    List<TransactionModel> transactions, {
    String currency = 'Rs.',
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    AppBottomSheet.show(
      context: context,
      title: 'Export & AI Spending Analysis',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, color: colorScheme.onPrimaryContainer, size: 20),
            ),
            title: const Text('Export CSV with AI Analysis Prompt', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Pre-loads structured prompt for Claude, ChatGPT, Gemini & NotebookLM'),
            onTap: () {
              Navigator.pop(context);
              shareTransactionsCsv(
                transactions,
                currency: currency,
                includeAiPrompt: true,
              );
            },
          ),
          const SizedBox(height: 4),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.copy_rounded, color: colorScheme.onSurfaceVariant, size: 20),
            ),
            title: const Text('Copy AI Prompt to Clipboard', style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: const Text('Copy prompt text to paste alongside your data in any LLM'),
            onTap: () async {
              Navigator.pop(context);
              final prompt = buildAiAnalysisPrompt(
                transactionCount: transactions.length,
                currency: currency,
              );
              await Clipboard.setData(ClipboardData(text: prompt));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('AI Analysis Prompt copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 4),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.table_chart_outlined, color: colorScheme.onSurfaceVariant, size: 20),
            ),
            title: const Text('Standard CSV Export', style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: const Text('Clean RFC 4180 CSV for Excel, Google Sheets, or Numbers'),
            onTap: () {
              Navigator.pop(context);
              shareTransactionsCsv(
                transactions,
                currency: currency,
                includeAiPrompt: false,
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
