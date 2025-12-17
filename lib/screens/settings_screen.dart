// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import '../data/database_helper.dart';

import 'package:provider/provider.dart';
import '../data/settings_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'manage_tags_screen.dart';
import '../theme/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<SettingsProvider>(builder: (context, settings, child) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              floating: true,
              snap: true,
              toolbarHeight: 84,
              automaticallyImplyLeading: false,
              title: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
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
                    Divider(
                        height: 1,
                        indent: 56,
                        color: Theme.of(context).colorScheme.outlineVariant),
                    _buildListTile(
                      context,
                      icon: Icons.format_paint_outlined,
                      title: 'Default Note Color',
                      trailing: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: settings.defaultNoteColor == 0
                              ? Theme.of(context).colorScheme.surface
                              : Color(settings.defaultNoteColor),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: settings.defaultNoteColor == 0
                            ? Icon(Icons.auto_awesome,
                                size: 12,
                                color: Theme.of(context).colorScheme.onSurface)
                            : null,
                      ),
                      onTap: () => _showDefaultColorPicker(context, settings),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'CONTENT'),
                  _buildSettingsContainer(context, [
                    _buildListTile(
                      context,
                      icon: Icons.label_outlined,
                      title: 'Manage Tags',
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
                      subtitle: 'Save notes to a JSON file',
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
                      subtitle: 'Restore from a JSON file',
                      showArrow: true,
                      onTap: () async {
                        await _importBackup(context);
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'ABOUT'),
                  _buildSettingsContainer(context, [
                    _buildListTile(
                      context,
                      icon: Icons.update,
                      title: 'Check for Updates',
                      subtitle: 'Check GitHub for latest release',
                      onTap: () => _checkForUpdates(context),
                    ),
                    Divider(
                        height: 1,
                        indent: 56,
                        color: Theme.of(context).colorScheme.outlineVariant),
                    _buildListTile(
                      context,
                      icon: Icons.public, // Or code/github icon if available
                      title: 'GitHub Releases',
                      subtitle: 'View release history',
                      trailing: Icon(Icons.open_in_new,
                          size: 20,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      onTap: () {
                        _launchUrl(
                            'https://github.com/SaadhJawwadh/Note-taking/releases');
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        );
      }),
    );
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

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        final file = File(
            '$selectedDirectory/notes_backup_${DateTime.now().millisecondsSinceEpoch}.json');
        await file
            .writeAsString(const JsonEncoder.withIndent('  ').convert(json));
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backup saved to ${file.path}')));
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Imported ${data.length} notes from backup')));
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(Uri.parse(
          'https://api.github.com/repos/SaadhJawwadh/Note-taking/releases/latest'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersionTag = data['tag_name'].toString();
        // Remove 'v' prefix if present
        final latestVersion = latestVersionTag.startsWith('v')
            ? latestVersionTag.substring(1)
            : latestVersionTag;

        bool isNewer = _isVersionNewer(currentVersion, latestVersion);

        if (isNewer) {
          // ignore: use_build_context_synchronously
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Update Available'),
              content: Text('A new version $latestVersionTag is available.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _launchUrl(data['html_url']);
                  },
                  child: const Text('Download'),
                ),
              ],
            ),
          );
        } else {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are using the latest version.')),
          );
        }
      } else {
        throw Exception('Failed to fetch release info');
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update check failed: $e')),
      );
    }
  }

  bool _isVersionNewer(String current, String latest) {
    // Simple comparison, might need semantic version parsing if complex
    // Assuming version string like 1.0.0
    return current != latest; // Very basic check
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
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

  void _showDefaultColorPicker(
      BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          title: Text('Default Note Color',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: AppTheme.noteColors.map((c) {
              final bool isSystem = c.toARGB32() == 0;
              final bool isSelected = settings.defaultNoteColor == c.toARGB32();

              return Tooltip(
                message: isSystem ? 'System Default' : 'Color',
                child: GestureDetector(
                  onTap: () {
                    settings.setDefaultNoteColor(c.toARGB32());
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: isSystem
                            ? Theme.of(context).colorScheme.surface
                            : c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: (isSystem ? Colors.black : c)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                        ]),
                    child: isSystem
                        ? Icon(Icons.auto_awesome,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface)
                        : (isSelected
                            ? Icon(Icons.check,
                                size: 24,
                                color: c.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white)
                            : null),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
