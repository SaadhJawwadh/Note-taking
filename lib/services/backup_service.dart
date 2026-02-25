import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../data/database_helper.dart';

// ── WorkManager task name ────────────────────────────────────────────────────
const kAutoBackupTaskName = 'com.example.note_taking_app.autoBackup';

// ── Top-level callback dispatcher — MUST be top-level ────────────────────────
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == kAutoBackupTaskName) {
      return await performAutoBackup();
    }
    return Future.value(true);
  });
}

// ── Generate backup JSON (reusable by both manual and auto backup) ───────────
/// Queries all DB tables and app settings, returns a JSON string in the same
/// v6 format used by manual export. Reads settings directly from
/// SharedPreferences so it works in a background isolate (no BuildContext).
Future<String> generateBackupJson() async {
  final db = await DatabaseHelper.instance.database;
  final notes = await db.query('notes');
  final tags = await db.query('tags');
  final transactions = await db.query('transactions');
  final categoryDefinitions = await db.query('category_definitions');
  final smsContacts = await db.query('sms_contacts');

  final prefs = await SharedPreferences.getInstance();
  final settingsMap = {
    'textSize': prefs.getDouble('textSize') ?? 16.0,
    'themeMode': prefs.getInt('themeMode') ?? 0,
    'fontFamily': prefs.getString('fontFamily') ?? 'Rubik',
    'isGridView': prefs.getBool('isGridView') ?? true,
    'showFinancialManager': prefs.getBool('showFinancialManager') ?? false,
    'currency': prefs.getString('currency') ?? 'LKR',
  };

  final backupData = {
    'notes': notes,
    'tags': tags,
    'transactions': transactions,
    'categoryDefinitions': categoryDefinitions,
    'smsContacts': smsContacts,
    'settings': settingsMap,
    'version': 6,
    'exportedAt': DateTime.now().toIso8601String(),
  };

  return const JsonEncoder.withIndent('  ').convert(backupData);
}

// ── Perform auto-backup (called from WorkManager callback) ───────────────────
Future<bool> performAutoBackup() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('autoBackupEnabled') ?? false;
    if (!enabled) return true;

    // Determine target directory
    String? targetPath = prefs.getString('autoBackupPath');

    // Validate the stored path still exists
    if (targetPath != null) {
      final dir = Directory(targetPath);
      if (!await dir.exists()) {
        targetPath = null;
      }
    }

    // Fallback: app's own external storage directory (always writable)
    if (targetPath == null) {
      final appDir = await getExternalStorageDirectory();
      if (appDir == null) return false;
      targetPath = appDir.path;
    }

    final jsonContent = await generateBackupJson();

    // Write file with date-stamped name
    final dateStr = DateTime.now()
        .toString()
        .replaceAll(RegExp(r'[: ]'), '_')
        .split('.')[0];
    final file = File('$targetPath/notebook_auto_backup_$dateStr.json');
    await file.writeAsString(jsonContent);

    // Record timestamp
    await prefs.setString(
        'lastAutoBackupTime', DateTime.now().toIso8601String());

    // Rotate: keep only the last 5 auto-backups
    await _rotateBackups(targetPath);

    return true;
  } catch (e, st) {
    // Log to system log (visible in logcat) so backup failures are debuggable
    // ignore: avoid_print
    print('AutoBackup failed: $e\n$st');
    return false;
  }
}

// ── Rotation — keep last 5 auto-backup files ─────────────────────────────────
Future<void> _rotateBackups(String directoryPath) async {
  final dir = Directory(directoryPath);
  if (!await dir.exists()) return;

  final autoBackupFiles = <File>[];
  await for (final entity in dir.list()) {
    if (entity is File &&
        entity.path.contains('notebook_auto_backup_') &&
        entity.path.endsWith('.json')) {
      autoBackupFiles.add(entity);
    }
  }

  if (autoBackupFiles.length <= 5) return;

  // Sort by modification time descending (newest first)
  autoBackupFiles.sort((a, b) =>
      b.lastModifiedSync().compareTo(a.lastModifiedSync()));

  // Delete all beyond the 5th
  for (final old in autoBackupFiles.skip(5)) {
    try {
      await old.delete();
    } catch (e) {
      // Best-effort deletion; log and continue
      // ignore: avoid_print
      print('Failed to delete old backup ${old.path}: $e');
    }
  }
}

// ── Schedule management ──────────────────────────────────────────────────────
/// Registers or cancels the periodic WorkManager task based on current
/// auto-backup settings in SharedPreferences.
Future<void> syncAutoBackupSchedule() async {
  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool('autoBackupEnabled') ?? false;

  if (!enabled) {
    await Workmanager().cancelByUniqueName(kAutoBackupTaskName);
    return;
  }

  final frequency = prefs.getString('autoBackupFrequency') ?? 'daily';
  final Duration interval;
  switch (frequency) {
    case 'weekly':
      interval = const Duration(days: 7);
    case 'monthly':
      interval = const Duration(days: 30);
    case 'daily':
    default:
      interval = const Duration(hours: 24);
  }

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
