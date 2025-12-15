// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database_helper.dart';

import 'package:provider/provider.dart';
import '../data/settings_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'manage_tags_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('Settings'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('Done',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface)),
              ),
            ),
          ],
        ),
        body: Consumer<SettingsProvider>(builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(context, 'APPEARANCE'),
              _buildSettingsContainer(context, [
                _buildListTile(
                  context,
                  icon: Icons.palette_outlined,
                  title: 'Theme',
                  subtitle: _getThemeLabel(settings.themeMode),
                  onTap: () => _showThemePicker(context, settings),
                ),
                Divider(
                    height: 1,
                    indent: 56,
                    color: Theme.of(context).colorScheme.outlineVariant),
                _buildListTile(
                  context,
                  icon: Icons.text_fields,
                  title: 'Text Size',
                  subtitle: settings.textSizeLabel,
                  onTap: () => _showTextSizePicker(context, settings),
                ),
                Divider(
                    height: 1,
                    indent: 56,
                    color: Theme.of(context).colorScheme.outlineVariant),
                _buildListTile(
                  context,
                  icon: Icons.font_download_outlined,
                  title: 'App Font',
                  subtitle: settings.fontFamily,
                  onTap: () => _showFontPicker(context, settings),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'CONTENT'),
              _buildSettingsContainer(context, [
                _buildListTile(
                  context,
                  icon: Icons.label_outlined,
                  title: 'Manage Categories',
                  subtitle: 'Rename or delete tags',
                  showArrow: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ManageTagsScreen()),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'DATA'),
              _buildSettingsContainer(context, [
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
                Divider(
                    height: 1,
                    indent: 56,
                    color: Theme.of(context).colorScheme.outlineVariant),
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
              _buildSettingsContainer(context, [
                _buildListTile(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  trailing: Icon(Icons.open_in_new,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Divider(
                    height: 1,
                    indent: 56,
                    color: Theme.of(context).colorScheme.outlineVariant),
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

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  void _showThemePicker(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          title: Text('Choose Theme',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: Text('System Default',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface)),
                value: ThemeMode.system,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  settings.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text('Light',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface)),
                value: ThemeMode.light,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  settings.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text('Dark',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface)),
                value: ThemeMode.dark,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  settings.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTextSizePicker(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          title: Text('Text Size',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<double>(
                title: Text('Small',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface)),
                value: 14.0,
                groupValue: settings.textSize,
                onChanged: (value) {
                  if (value != null) {
                    settings.setTextSize(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<double>(
                title: Text('Medium',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface)),
                value: 16.0,
                groupValue: settings.textSize,
                onChanged: (value) {
                  if (value != null) {
                    settings.setTextSize(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<double>(
                title: Text('Large',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface)),
                value: 20.0,
                groupValue: settings.textSize,
                onChanged: (value) {
                  if (value != null) {
                    settings.setTextSize(value);
                    Navigator.pop(context);
                  }
                },
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
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSettingsContainer(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
      leading:
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant))
          : null,
      trailing: trailing ??
          (showArrow
              ? Icon(Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)
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

  void _showFontPicker(BuildContext context, SettingsProvider settings) {
    final fonts = ['Rubik', 'Comic Neue', 'Sans Serif'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          title: Text('App Font',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: fonts.map((font) {
              return RadioListTile<String>(
                title: Text(font,
                    style: TextStyle(
                        fontFamily: font == 'Sans Serif'
                            ? null
                            : GoogleFonts.getFont(font).fontFamily,
                        color: Theme.of(context).colorScheme.onSurface)),
                value: font,
                groupValue: settings.fontFamily,
                onChanged: (value) {
                  if (value != null) {
                    settings.setFontFamily(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
