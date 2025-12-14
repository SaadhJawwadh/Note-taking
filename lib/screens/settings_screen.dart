import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database_helper.dart';
import '../theme/app_theme.dart';

import 'package:provider/provider.dart';
import '../data/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF3A3A3C),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child:
                    const Text('Done', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
        body: Consumer<SettingsProvider>(builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(context, 'APPEARANCE'),
              _buildSettingsContainer([
                _buildListTile(
                  context,
                  icon: Icons.palette,
                  title: 'Theme',
                  subtitle: 'Dark Noir',
                ),
                const Divider(height: 1, indent: 56),
                _buildListTile(
                  context,
                  icon: Icons.grid_view,
                  title: 'App Icon',
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _buildListTile(
                  context,
                  icon: Icons.text_fields,
                  title: 'Text Size',
                  subtitle: settings.textSizeLabel,
                  onTap: () => _showTextSizePicker(context, settings),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'PREFERENCES'),
              _buildSettingsContainer([
                _buildListTile(
                  context,
                  icon: Icons.notifications,
                  title: 'Notifications',
                  showArrow: true,
                ),
                const Divider(height: 1, indent: 56),
                _buildListTile(
                  context,
                  icon: Icons.volume_up,
                  title: 'In-App Sounds',
                  trailing: CupertinoSwitch(
                      value: settings.enableSounds,
                      onChanged: (v) => settings.setSounds(v),
                      activeTrackColor: AppTheme.primaryPurple),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'SECURITY'),
              _buildSettingsContainer([
                _buildListTile(
                  context,
                  icon: Icons.face,
                  title: 'Face ID Lock',
                  subtitle: 'Require for access',
                  trailing: CupertinoSwitch(
                      value: settings.enableFaceId,
                      onChanged: (v) => settings.setFaceId(v),
                      activeTrackColor: AppTheme.primaryPurple),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'DATA'),
              _buildSettingsContainer([
                _buildListTile(
                  context,
                  icon: Icons.download_outlined,
                  title: 'Export Backup',
                  subtitle: 'Save notes to a local JSON file',
                  showArrow: true,
                  onTap: () async {
                    await _exportBackup(context);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildListTile(
                  context,
                  icon: Icons.upload_outlined,
                  title: 'Import Backup',
                  subtitle: 'Restore from local JSON file',
                  showArrow: true,
                  onTap: () async {
                    await _importBackup(context);
                  },
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'SUPPORT'),
              _buildSettingsContainer([
                _buildListTile(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  trailing: const Icon(Icons.open_in_new,
                      size: 20, color: Colors.grey),
                ),
                const Divider(height: 1, indent: 56),
                _buildListTile(
                  context,
                  icon: Icons.chat_bubble_outline,
                  title: 'Send Feedback',
                ),
              ]),
              const SizedBox(height: 24),
            ],
          );
        }));
  }

  void _showTextSizePicker(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: const Text('Text Size', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<double>(
                title:
                    const Text('Small', style: TextStyle(color: Colors.white)),
                value: 14.0,
                groupValue: settings.textSize,
                onChanged: (value) {
                  if (value != null) {
                    settings.setTextSize(value);
                    Navigator.pop(context);
                  }
                },
                activeColor: AppTheme.primaryPurple,
              ),
              RadioListTile<double>(
                title:
                    const Text('Medium', style: TextStyle(color: Colors.white)),
                value: 16.0,
                groupValue: settings.textSize,
                onChanged: (value) {
                  if (value != null) {
                    settings.setTextSize(value);
                    Navigator.pop(context);
                  }
                },
                activeColor: AppTheme.primaryPurple,
              ),
              RadioListTile<double>(
                title:
                    const Text('Large', style: TextStyle(color: Colors.white)),
                value: 20.0,
                groupValue: settings.textSize,
                onChanged: (value) {
                  if (value != null) {
                    settings.setTextSize(value);
                    Navigator.pop(context);
                  }
                },
                activeColor: AppTheme.primaryPurple,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.grey))
          : null,
      trailing: trailing ??
          (showArrow
              ? const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey)
              : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('notes');
      final json = rows.map((e) => e).toList();
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/notes_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file
          .writeAsString(const JsonEncoder.withIndent('  ').convert(json));
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup saved to ${file.path}')));
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      var file = File('${dir.path}/notes_backup.json');
      if (!await file.exists()) {
        // Try most recent backup file by pattern
        final files = dir
            .listSync()
            .whereType<File>()
            .where((f) =>
                f.path.contains('notes_backup_') && f.path.endsWith('.json'))
            .toList()
          ..sort(
              (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        if (files.isEmpty) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No backup file found in app documents folder')));
          return;
        }
        file = files.first;
      }

      final content = await file.readAsString();
      final List<dynamic> data = jsonDecode(content);
      final db = await DatabaseHelper.instance.database;
      final batch = db.batch();
      for (final row in data) {
        batch.insert('notes', Map<String, Object?>.from(row),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${data.length} notes from backup')));
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }
}
