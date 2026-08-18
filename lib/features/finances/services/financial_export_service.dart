import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../data/transaction_model.dart';
import '../../../../screens/app_lock_screen.dart';

/// Service for exporting financial transaction ledgers to CSV and JSON formats.
class FinancialExportService {
  FinancialExportService._();

  /// Converts a list of [TransactionModel] records into standard RFC 4180 CSV format.
  static String generateCsv(List<TransactionModel> transactions, {String currency = 'Rs.'}) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('Date,Time,Description,Category,Type,Amount,Currency,SMS_ID');

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm:ss');

    for (final tx in transactions) {
      final dateStr = dateFormat.format(tx.date);
      final timeStr = timeFormat.format(tx.date);
      final escapedDesc = _escapeCsvField(tx.description);
      final escapedCategory = _escapeCsvField(tx.category);
      final typeStr = tx.isExpense ? 'Expense' : 'Income';
      final amountStr = tx.amount.toStringAsFixed(2);
      final escapedCurrency = _escapeCsvField(currency);
      final smsIdStr = tx.smsId ?? '';

      buffer.writeln('$dateStr,$timeStr,$escapedDesc,$escapedCategory,$typeStr,$amountStr,$escapedCurrency,$smsIdStr');
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

  /// Shares a list of transactions as an exported `.csv` file via the system share sheet.
  static Future<void> shareTransactionsCsv(
    List<TransactionModel> transactions, {
    String currency = 'Rs.',
    String filePrefix = 'transactions_export',
  }) async {
    final csvContent = generateCsv(transactions, currency: currency);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${tempDir.path}/${filePrefix}_$timestamp.csv');
    await file.writeAsString(csvContent);

    AppLockScreen.ignoreNextResumeLock();
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: 'Exported ${transactions.length} transactions ($currency)',
      subject: 'Financial Ledger Export',
    );
  }
}
