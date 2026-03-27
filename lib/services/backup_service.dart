import 'package:sqflite_sqlcipher/sqflite.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../data/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';
import '../data/transaction_category.dart';
import 'sms_service.dart';

const kAutoBackupTaskName = 'com.example.note_taking_app.autoBackup';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == kAutoBackupTaskName) return await performAutoBackup();
    return Future.value(true);
  });
}

/// Generate backup JSON. Optionally pass [settingsOverride] from
/// [SettingsProvider.toBackupMap()] so all settings are captured. When called
/// from an isolate (auto-backup) where BuildContext is unavailable, falls back
/// to reading the stored prefs directly (best-effort).
Future<String> generateBackupJson({Map<String, dynamic>? settingsOverride}) async {
  final db = await DatabaseHelper.instance.database;
  final notes = await db.query('notes');
  final tags = await db.query('tags');
  final noteTags = await db.query('note_tags');
  final transactions = await db.query('transactions');
  final categoryDefinitions = await db.query('category_definitions');
  final smsContacts = await db.query('sms_contacts');
  final periodLogs = await db.query('period_logs');

  final Map<String, dynamic> settingsMap;
  if (settingsOverride != null) {
    settingsMap = settingsOverride;
  } else {
    // Fallback for isolate / auto-backup context (no SettingsProvider).
    final prefs = await SharedPreferences.getInstance();
    settingsMap = {
      'textSize': prefs.getDouble('textSize') ?? 16.0,
      'themeMode': prefs.getInt('themeMode') ?? 0,
      'fontFamily': prefs.getString('fontFamily') ?? 'Rubik',
      'noteViewMode': prefs.getInt('noteViewMode') ?? 1,
      'isGridView': prefs.getBool('isGridView') ?? true, // legacy
      'showFinancialManager': prefs.getBool('showFinancialManager') ?? false,
      'showFileConverter': prefs.getBool('showFileConverter') ?? false,
      'isConverterLite': prefs.getBool('isConverterLite') ?? true,
      'currency': prefs.getString('currency') ?? 'LKR',
      'isPeriodTrackerEnabled': prefs.getBool('isPeriodTrackerEnabled') ?? false,
      'discreetNotificationText': prefs.getString('discreetNotificationText') ?? 'Check the app',
      'customExpenseRules': prefs.getStringList('customExpenseRules') ?? [],
      'customIncomeRules': prefs.getStringList('customIncomeRules') ?? [],
      'preferredVideoFormat': prefs.getString('preferredVideoFormat') ?? 'mp4',
      'preferredImageFormat': prefs.getString('preferredImageFormat') ?? 'jpg',
      'videoResolutionLimit': prefs.getString('videoResolutionLimit') ?? 'Original',
      'keepMetadata': prefs.getBool('keepMetadata') ?? false,
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
    'settings': settingsMap,
    'version': 9,
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
      final appDir = await getExternalStorageDirectory();
      if (appDir == null) return false;
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
}

class BackupService {
  static Future<void> exportBackup(BuildContext context) async {
    try {
      // Pass the full settings map from SettingsProvider to ensure all fields
      // are captured (noteViewMode, showFileConverter, custom rules, etc.).
      final settingsMap = context.mounted
          ? Provider.of<SettingsProvider>(context, listen: false).toBackupMap()
          : null;
      final json = await generateBackupJson(settingsOverride: settingsMap);
      final dir = await FilePicker.platform.getDirectoryPath();
      if (dir != null) {
        final dateStr = DateTime.now().toString().replaceAll(RegExp(r'[: ]'), '_').split('.')[0];
        final file = File('$dir/notebook_backup_$dateStr.json');
        await file.writeAsString(json);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup saved to ${file.path}'), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: Theme.of(context).colorScheme.error, behavior: SnackBarBehavior.floating));
    }
  }

  static Future<void> importBackup(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.single.path == null) return;
      final content = await File(result.files.single.path!).readAsString();
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
        await txn.delete('note_tags'); // Clear explicit associations
        // Built-in categories and contacts are kept, but we replace custom ones
        await txn.delete('category_definitions', where: 'isBuiltIn = 0');
        await txn.delete('sms_contacts', where: 'isBuiltIn = 0');

        final batch = txn.batch();

        if (data.containsKey('notes')) {
          for (final row in data['notes']) {
            final map = Map<String, Object?>.from(row)..remove('tags'); // Omit legacy tags column
            batch.insert('notes', map, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (data.containsKey('tags')) {
          for (final row in data['tags']) {
            batch.insert('tags', Map<String, Object?>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (data.containsKey('noteTags')) {
          for (final row in data['noteTags']) {
            batch.insert('note_tags', Map<String, Object?>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
          }
        } else if (data.containsKey('notes')) {
          // Fallback for older backups: reconstruct note_tags from notes column
          for (final row in data['notes']) {
            final id = row['id'] as String?;
            final tagsJson = row['tags'] as String?;
            if (id != null && tagsJson != null) {
              try {
                final List<dynamic> tags = jsonDecode(tagsJson);
                for (final tag in tags) {
                  batch.insert('note_tags', {'note_id': id, 'tag_name': tag.toString()}, conflictAlgorithm: ConflictAlgorithm.ignore);
                }
              } catch (_) {}
            }
          }
        }
        if (data.containsKey('transactions')) {
          for (final row in data['transactions']) {
            final map = Map<String, Object?>.from(row)
              ..remove('_id') // Let DB generate ID
              ..remove('id'); // Ensure no collision with 'id' if exists
            batch.insert('transactions', map, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
        if (data.containsKey('categoryDefinitions')) {
          for (final row in data['categoryDefinitions']) {
            final map = Map<String, Object?>.from(row);
            batch.insert('category_definitions', map, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (data.containsKey('smsContacts')) {
          for (final row in data['smsContacts']) {
            batch.insert('sms_contacts', Map<String, Object?>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
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
}
