import 'package:sqflite_sqlcipher/sqflite.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../data/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../screens/app_lock_screen.dart';
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';
import '../data/transaction_category.dart';
import '../data/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/recurring_rule_repository.dart';
import '../providers/note_provider.dart';
import '../utils/rich_text_utils.dart';
import '../utils/widget_helper.dart';
import 'sms_service.dart';

const kAutoBackupTaskName = 'com.saadhjawwadh.notebook.autoBackup';

@pragma('vm:entry-point')
void callbackDispatcher() {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
  try {
    Workmanager().executeTask((task, inputData) async {
      if (task == kAutoBackupTaskName) return await performAutoBackup();
      if (task == SmsService.kDailySyncTaskName) return await SmsService.performDailyTransactionSync();
      if (task == kWidgetRefreshTaskName) {
        // Recomputes widget prefs; the widget's own updatePeriodMillis cycle
        // redraws from them since the widget channel isn't available here.
        await WidgetHelper.updateWidgetData();
        return true;
      }
      return Future.value(true);
    });
  } catch (e) {
    debugPrint('Workmanager executeTask error: $e');
  }
}

/// Generate backup JSON. Optionally pass [settingsOverride] from
/// [SettingsProvider.toBackupMap()] so all settings are captured. When called
/// from an isolate (auto-backup) where BuildContext is unavailable, falls back
/// to reading the stored prefs directly (best-effort).
Future<String> generateBackupJson({Map<String, dynamic>? settingsOverride}) async {
  // 1. Materialize any due recurring transactions before snapshotting
  try {
    await RecurringRuleRepository.instance.materializeDueRules();
  } catch (_) {}

  final db = await DatabaseHelper.instance.database;

  // 2. Passive SQLite WAL checkpoint to ensure writes are committed without blocking
  try {
    await db.rawQuery('PRAGMA wal_checkpoint(PASSIVE);');
  } catch (_) {}

  final notes = await db.query('notes');
  final tags = await db.query('tags');
  final noteTags = await db.query('note_tags');
  final transactions = await db.query('transactions', orderBy: '${TransactionFields.id} ASC');
  final categoryDefinitions = await db.query('category_definitions');
  final smsContacts = await db.query('sms_contacts');
  final periodLogs = await db.query('period_logs');
  final recurringRules = await db.query('recurring_rules');

  final Map<String, dynamic> settingsMap;
  if (settingsOverride != null) {
    settingsMap = settingsOverride;
  } else {
    // Fallback for isolate / auto-backup context (no SettingsProvider).
    final prefs = await SharedPreferences.getInstance();
    settingsMap = {
      'textSize': prefs.getDouble('textSize') ?? 16.0,
      'themeMode': prefs.getInt('themeMode') ?? 0,
      'noteViewMode': prefs.getInt('noteViewMode') ?? 1,
      'isGridView': prefs.getBool('isGridView') ?? true, // legacy
      'showFinancialManager': prefs.getBool('showFinancialManager') ?? false,
      'currency': prefs.getString('currency') ?? 'LKR',
      'isPeriodTrackerEnabled': prefs.getBool('isPeriodTrackerEnabled') ?? false,
      'appLockEnabled': prefs.getBool('appLockEnabled') ?? false,
      'useBiometrics': prefs.getBool('useBiometrics') ?? false,
      'appLockTimeout': prefs.getInt('appLockTimeout') ?? 0,
      'discreetNotificationText': prefs.getString('discreetNotificationText') ?? 'Check the app',
      'customExpenseRules': prefs.getStringList('customExpenseRules') ?? [],
      'customIncomeRules': prefs.getStringList('customIncomeRules') ?? [],
      'useOnDeviceAi': prefs.getBool('useOnDeviceAi') ?? false,
    };
  }

  return const JsonEncoder.withIndent('  ').convert({
    'notes': notes,
    'tags': tags,
    'noteTags': noteTags,
    'transactions': transactions,
    'categoryDefinitions': categoryDefinitions,
    'smsContacts': smsContacts,
    'periodLogs': periodLogs,
    'recurringRules': recurringRules,
    'settings': settingsMap,
    'version': 10,
    'exportedAt': DateTime.now().toIso8601String(),
  });
}

Future<bool> performAutoBackup() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('autoBackupEnabled') ?? false)) return true;
    String? targetPath = prefs.getString('autoBackupPath');
    if (targetPath != null && !await Directory(targetPath).exists()) targetPath = null;
    if (targetPath == null) {
      final appDir = await getApplicationDocumentsDirectory();
      targetPath = appDir.path;
    }
    final jsonContent = await generateBackupJson();
    final dateStr = DateTime.now().toString().replaceAll(RegExp(r'[: ]'), '_').split('.')[0];
    final file = File('$targetPath/notebook_auto_backup_$dateStr.json');
    await file.writeAsString(jsonContent);
    await prefs.setString('lastAutoBackupTime', DateTime.now().toIso8601String());
    await _rotateBackups(targetPath);
    return true;
  } catch (e) {
    debugPrint('AutoBackup failed: $e');
    return false;
  }
}

Future<void> _rotateBackups(String directoryPath) async {
  final dir = Directory(directoryPath);
  if (!await dir.exists()) return;
  final files = <File>[];
  await for (final entity in dir.list()) {
    if (entity is File && entity.path.contains('notebook_auto_backup_') && entity.path.endsWith('.json')) files.add(entity);
  }
  if (files.length <= 5) return;
  files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  for (final old in files.skip(5)) {
    try { await old.delete(); } catch (_) {}
  }
}

Future<void> syncAutoBackupSchedule() async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('autoBackupEnabled') ?? false)) {
      await Workmanager().cancelByUniqueName(kAutoBackupTaskName);
      return;
    }
    final frequency = prefs.getString('autoBackupFrequency') ?? 'daily';
    final interval = frequency == 'weekly' ? const Duration(days: 7) : (frequency == 'monthly' ? const Duration(days: 30) : const Duration(hours: 24));
    await Workmanager().registerPeriodicTask(
      kAutoBackupTaskName,
      kAutoBackupTaskName,
      frequency: interval,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  } catch (e) {
    debugPrint('Workmanager syncAutoBackupSchedule error: $e');
  }
}

class BackupService {
  static Future<void> exportBackup(BuildContext context) async {
    try {
      // Pass the full settings map from SettingsProvider to ensure all fields
      // are captured (noteViewMode, custom rules, etc.).
      final settingsMap = context.mounted
          ? Provider.of<SettingsProvider>(context, listen: false).toBackupMap()
          : null;
      final json = await generateBackupJson(settingsOverride: settingsMap);
      AppLockScreen.ignoreNextResumeLock();
      
      String? dir;
      try {
        dir = await FilePicker.platform.getDirectoryPath();
      } catch (_) {
        dir = null;
      }

      final dateStr = DateTime.now().toString().replaceAll(RegExp(r'[: ]'), '_').split('.')[0];
      
      if (dir != null) {
        final file = File('$dir/notebook_backup_$dateStr.json');
        await file.writeAsString(json);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backup saved to ${file.path}'), behavior: SnackBarBehavior.floating),
          );
        }
      } else {
        // Fallback to temp file + Share sheet if directory picker is unavailable or cancelled
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/notebook_backup_$dateStr.json');
        await file.writeAsString(json);
        await Share.shareXFiles([XFile(file.path)], text: 'Everything App Backup ($dateStr)');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static Future<void> importBackup(BuildContext context) async {
    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
      } catch (e) {
        debugPrint('JSON pickFiles error: $e');
      }
      if (result == null || result.files.isEmpty || result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final data = Map<String, dynamic>.from(jsonDecode(content) as Map);

      if (context.mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Backup?'),
            content: const Text('This will overwrite existing data. Continue?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
            ],
          ),
        );
        if (confirmed != true) return;
      }

      final db = await DatabaseHelper.instance.database;
      
      await db.transaction((txn) async {
        // Clear existing dynamic data to ensure integrity
        await txn.delete('notes');
        await txn.delete('tags');
        await txn.delete('note_tags');
        await txn.delete('transactions');
        await txn.delete('period_logs');
        await txn.delete('recurring_rules');
        // Built-in categories and contacts are kept, but we replace custom ones
        await txn.delete('category_definitions', where: 'isBuiltIn = 0');
        await txn.delete('sms_contacts', where: 'isBuiltIn = 0');

        final batch = txn.batch();

        if (data.containsKey('notes')) {
          for (final row in data['notes']) {
            final map = Map<String, Object?>.from(row)..remove('tags'); // Omit legacy tags column
            if (map['isArchived'] is bool) {
              map['isArchived'] = (map['isArchived'] as bool) ? 1 : 0;
            }
            if (map['isPinned'] is bool) {
              map['isPinned'] = (map['isPinned'] as bool) ? 1 : 0;
            }
            if (!map.containsKey('previewText') || map['previewText'] == null) {
              final content = map['content'] as String? ?? '';
              map['previewText'] = RichTextUtils.contentToPlainText(content, maxLines: 6);
            }
            if (!map.containsKey('category') || map['category'] == null || (map['category'] as String).isEmpty) {
              map['category'] = 'Notes';
            }
            batch.insert('notes', map, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (data.containsKey('tags')) {
          for (final row in data['tags']) {
            final map = Map<String, Object?>.from(row);
            if (map['name'] != null) {
              batch.insert('tags', map, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
        if (data.containsKey('noteTags')) {
          for (final row in data['noteTags']) {
            final map = Map<String, Object?>.from(row);
            final tagName = map['tag_name'] as String?;
            if (tagName != null && tagName.isNotEmpty) {
              batch.insert('tags', {'name': tagName}, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
            batch.insert('note_tags', map, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        } else if (data.containsKey('notes')) {
          // Fallback for older backups: reconstruct note_tags and tags from notes column
          for (final row in data['notes']) {
            final id = row['id'] as String?;
            final tagsJson = row['tags'] as String?;
            if (id != null && tagsJson != null) {
              try {
                final List<dynamic> tags = jsonDecode(tagsJson);
                for (final tag in tags) {
                  final tagName = tag.toString().trim();
                  if (tagName.isNotEmpty) {
                    batch.insert('tags', {'name': tagName}, conflictAlgorithm: ConflictAlgorithm.ignore);
                    batch.insert('note_tags', {'note_id': id, 'tag_name': tagName}, conflictAlgorithm: ConflictAlgorithm.ignore);
                  }
                }
              } catch (_) {}
            }
          }
        }
        if (data.containsKey('transactions')) {
          for (final row in data['transactions']) {
            final map = Map<String, Object?>.from(row)..remove('_id');
            if (map['isExpense'] is bool) {
              map['isExpense'] = (map['isExpense'] as bool) ? 1 : 0;
            }
            if (!map.containsKey('category') || map['category'] == null) {
              map['category'] = 'Other';
            }
            batch.insert('transactions', map, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (data.containsKey('recurringRules')) {
          for (final row in data['recurringRules']) {
            final map = Map<String, Object?>.from(row);
            if (map['isExpense'] is bool) {
              map['isExpense'] = (map['isExpense'] as bool) ? 1 : 0;
            }
            batch.insert('recurring_rules', map, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (data.containsKey('categoryDefinitions')) {
          for (final row in data['categoryDefinitions']) {
            final map = Map<String, Object?>.from(row);
            if (map['isBuiltIn'] is bool) {
              map['isBuiltIn'] = (map['isBuiltIn'] as bool) ? 1 : 0;
            }
            batch.insert('category_definitions', map, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (data.containsKey('smsContacts')) {
          for (final row in data['smsContacts']) {
            final map = Map<String, Object?>.from(row);
            if (map['isBuiltIn'] is bool) {
              map['isBuiltIn'] = (map['isBuiltIn'] as bool) ? 1 : 0;
            }
            batch.insert('sms_contacts', map, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (data.containsKey('periodLogs')) {
          for (final row in data['periodLogs']) {
            batch.insert('period_logs', Map<String, Object?>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        await batch.commit(noResult: true);
      });

      await TransactionCategory.reload();
      await SmsService.reloadSmsContacts();
      await WidgetHelper.updateWidgetData();

      if (context.mounted) {
        try {
          await Provider.of<NoteProvider>(context, listen: false).refreshNotes();
        } catch (e) {
          debugPrint('NoteProvider refresh error: $e');
        }
      }

      if (context.mounted && data.containsKey('settings')) {
        await Provider.of<SettingsProvider>(context, listen: false).restoreFromBackupMap(Map<String, dynamic>.from(data['settings'] as Map));
      }

      if (context.mounted) {
        // Use a slight delay to avoid Hero animation collisions if the UI is rebuilding
        Future.delayed(Duration.zero, () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Import successful'), behavior: SnackBarBehavior.floating),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Import error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static Future<void> exportTransactionsToCsv(BuildContext context) async {
    try {
      final transactions = await TransactionRepository.instance.readAllTransactions();
      if (transactions.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No transactions to export'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final csvBuffer = StringBuffer();
      // Write headers matching the fields of TransactionModel
      csvBuffer.writeln('ID,Date,Amount,Type,Category,Description,SMS ID');

      for (final TransactionModel tx in transactions) {
        final id = tx.id?.toString() ?? '';
        final date = tx.date.toIso8601String();
        final amount = tx.amount.toString();
        final type = tx.isExpense ? 'Expense' : 'Income';
        final category = _escapeCsvValue(tx.category);
        final description = _escapeCsvValue(tx.description);
        final smsId = tx.smsId != null ? _escapeCsvValue(tx.smsId!) : '';

        csvBuffer.writeln('$id,$date,$amount,$type,$category,$description,$smsId');
      }

      AppLockScreen.ignoreNextResumeLock();
      String? dir;
      try {
        dir = await FilePicker.platform.getDirectoryPath();
      } catch (_) {
        dir = null;
      }

      final dateStr = DateTime.now().toString().replaceAll(RegExp(r'[: ]'), '_').split('.')[0];

      if (dir != null) {
        final file = File('$dir/transactions_export_$dateStr.csv');
        await file.writeAsString(csvBuffer.toString());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transactions exported to ${file.path}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Fallback to temp file + Share sheet if directory picker is unavailable or cancelled
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/transactions_export_$dateStr.csv');
        await file.writeAsString(csvBuffer.toString());
        await Share.shareXFiles([XFile(file.path)], text: 'Transaction Ledger Export ($dateStr)');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static String _escapeCsvValue(String value) {
    if (value.contains('"') || value.contains(',') || value.contains('\n') || value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static List<Map<String, dynamic>> _parseCsvBufferInIsolate(String content) {
    final lines = const LineSplitter().convert(content);
    final results = <Map<String, dynamic>>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      if (i == 0 && (line.toLowerCase().contains('date') || line.toLowerCase().contains('amount'))) {
        continue;
      }

      final fields = _parseCsvLine(line);
      if (fields.length < 3) continue;

      DateTime? date;
      double? amount;
      bool isExpense = true;
      String category = 'Other';
      String description = 'CSV Imported';

      for (final field in fields) {
        final trimmed = field.trim();
        if (amount == null) {
          final parsedAmt = double.tryParse(trimmed.replaceAll(',', ''));
          if (parsedAmt != null && parsedAmt > 0) {
            amount = parsedAmt;
            continue;
          }
        }
        if (date == null) {
          final parsedDate = DateTime.tryParse(trimmed);
          if (parsedDate != null) {
            date = parsedDate;
            continue;
          }
        }
        if (trimmed.toLowerCase() == 'income' || trimmed.toLowerCase() == 'credit') {
          isExpense = false;
        } else if (trimmed.toLowerCase() == 'expense' || trimmed.toLowerCase() == 'debit') {
          isExpense = true;
        } else if (category == 'Other' && TransactionCategory.allNames.contains(trimmed)) {
          category = trimmed;
        } else if (description == 'CSV Imported' && trimmed.isNotEmpty && double.tryParse(trimmed) == null) {
          description = trimmed;
        }
      }

      if (amount != null) {
        results.add({
          'amount': amount,
          'description': description,
          'date': (date ?? DateTime.now()).toIso8601String(),
          'isExpense': isExpense,
          'category': category,
        });
      }
    }
    return results;
  }

  static Future<void> importTransactionsFromCsv(BuildContext context) async {
    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv', 'txt'],
        );
      } catch (e) {
        debugPrint('CSV pickFiles error: $e');
      }
      if (result == null || result.files.isEmpty || result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      if (!await file.exists()) return;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return;

      int importedCount = 0;
      final repository = TransactionRepository.instance;

      final parsedData = kIsWeb
          ? _parseCsvBufferInIsolate(content)
          : await Isolate.run(() => _parseCsvBufferInIsolate(content));

      for (final item in parsedData) {
        await repository.createTransaction(TransactionModel(
          amount: item['amount'] as double,
          description: item['description'] as String,
          date: DateTime.parse(item['date'] as String),
          isExpense: item['isExpense'] as bool,
          category: item['category'] as String,
        ));
        importedCount++;
      }

      await WidgetHelper.updateWidgetData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $importedCount transactions from CSV'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV import failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool insideQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        insideQuotes = !insideQuotes;
      } else if (char == ',' && !insideQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }
}
