// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:package_info_plus/package_info_plus.dart';

import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import '../data/database_helper.dart';

import 'package:provider/provider.dart';
import '../data/settings_provider.dart';

import 'manage_tags_screen.dart';
import 'filtered_notes_screen.dart';
import '../utils/app_constants.dart';

import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
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
                sliver: AnimationLimiter(
                  child: SliverList(
                    delegate: SliverChildListDelegate(
                      AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 375),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          horizontalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          _buildSectionHeader(context, 'FEATURES'),
                          _buildSettingsContainer(context, [
                            _buildSwitchTile(
                              context,
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Financial Manager',
                              subtitle: 'Enable expense tracking',
                              value: settings.showFinancialManager,
                              onChanged: (value) =>
                                  settings.setShowFinancialManager(value),
                            ),
                            if (settings.showFinancialManager) ...[
                              Divider(
                                height: 1,
                                indent: 56,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              _buildListTile(
                                context,
                                icon: Icons.currency_exchange_outlined,
                                title: 'Currency',
                                subtitle: settings.currency,
                                onTap: () =>
                                    _showCurrencyPicker(context, settings),
                              ),
                            ]
                          ]),
                          const SizedBox(height: 24),
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
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                            _buildListTile(
                              context,
                              icon: Icons.text_fields,
                              title: 'Text Size',
                              subtitle: settings.textSizeLabel,
                              onTap: () =>
                                  _showTextSizePicker(context, settings),
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildSectionHeader(context, 'CONTENT'),
                          _buildSettingsContainer(context, [
                            _buildListTile(
                              context,
                              icon: Icons.label_outline,
                              title: 'Manage Tags',
                              subtitle: 'Rename or delete tags',
                              showArrow: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ManageTagsScreen(),
                                  ),
                                );
                              },
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildSectionHeader(context, 'FOLDERS'),
                          _buildSettingsContainer(context, [
                            _buildListTile(
                              context,
                              icon: Icons.folder_open_outlined,
                              title: 'Archive',
                              subtitle: 'View archived notes',
                              showArrow: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const FilteredNotesScreen(
                                            filterType: FilterType.archived),
                                  ),
                                );
                              },
                            ),
                            Divider(
                              height: 1,
                              indent: 56,
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                            _buildListTile(
                              context,
                              icon: Icons.delete_outline,
                              title: 'Trash',
                              subtitle: 'View deleted notes',
                              showArrow: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const FilteredNotesScreen(
                                            filterType: FilterType.trash),
                                  ),
                                );
                              },
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildSectionHeader(context, 'DATA & SYNC'),
                          _buildSettingsContainer(context, [
                            _buildListTile(
                              context,
                              icon: Icons.download_outlined,
                              title: 'Export Backup',
                              subtitle: 'Save notes to a JSON file',
                              showArrow: true,
                              onTap: () => _exportBackup(context),
                            ),
                            Divider(
                              height: 1,
                              indent: 56,
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                            _buildListTile(
                              context,
                              icon: Icons.upload_outlined,
                              title: 'Import Backup',
                              subtitle: 'Restore from a JSON file',
                              showArrow: true,
                              onTap: () => _importBackup(context),
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildSectionHeader(context, 'ABOUT'),
                          _buildSettingsContainer(context, [
                            _buildListTile(
                              context,
                              icon: FontAwesomeIcons.github,
                              title: 'GitHub Repository',
                              subtitle: 'View source code & contribute',
                              trailing: Icon(
                                Icons.open_in_new_rounded,
                                size: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              onTap: () => _launchUrl(AppConstants.repoUrl),
                            ),
                            Divider(
                              height: 1,
                              indent: 56,
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                            FutureBuilder<PackageInfo>(
                              future: PackageInfo.fromPlatform(),
                              builder: (context, snapshot) {
                                String version = 'Loading...';
                                if (snapshot.hasData) {
                                  version =
                                      '${snapshot.data!.version}+${snapshot.data!.buildNumber}';
                                }
                                return _buildListTile(
                                  context,
                                  icon: Icons.info_outline_rounded,
                                  title: 'Version',
                                  subtitle:
                                      snapshot.hasData ? 'v$version' : version,
                                  onTap: () =>
                                      _launchUrl(AppConstants.releaseUrl),
                                );
                              },
                            ),
                          ]),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
          title: Text(
            'Choose Theme',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: Text(
                  'System Default',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                value: ThemeMode.system,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  settings.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(
                  'Light',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                value: ThemeMode.light,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  settings.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(
                  'Dark',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
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
          title: Text(
            'Text Size',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<double>(
                title: Text(
                  'Small',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
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
                title: Text(
                  'Medium',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
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
                title: Text(
                  'Large',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
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

  void _showCurrencyPicker(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AppConstants.currencies.length,
              itemBuilder: (context, index) {
                final currency = AppConstants.currencies[index];
                return RadioListTile<String>(
                  title: Text(currency),
                  value: currency,
                  groupValue: settings.currency,
                  onChanged: (value) {
                    if (value != null) {
                      settings.setCurrency(value);
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
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
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: trailing ??
          (showArrow
              ? Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
              : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final notes = await db.query('notes');
      final tags = await db.query('tags');
      final transactions = await db.query('transactions');

      final backupData = {
        'notes': notes,
        'tags': tags,
        'transactions': transactions,
        'version': 2, // Incremented version for new schema
        'exportedAt': DateTime.now().toIso8601String(),
      };

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        // Create filename with date and app name
        final dateStr = DateTime.now()
            .toString()
            .replaceAll(RegExp(r'[: ]'), '_')
            .split('.')[0];
        final file = File(
          '$selectedDirectory/notebook_backup_$dateStr.json',
        );

        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(backupData),
        );

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved successfully to ${file.path}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);

        final db = await DatabaseHelper.instance.database;
        final batch = db.batch();

        int notesCount = 0;
        int tagsCount = 0;
        int transactionsCount = 0;

        // Handle Notes
        if (data.containsKey('notes')) {
          final List<dynamic> notes = data['notes'];
          notesCount = notes.length;
          for (final row in notes) {
            batch.insert(
              'notes',
              Map<String, Object?>.from(row),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
        // Legacy format check (root level list)
        else if (data is List) {
          final List<dynamic> notes = data as List;
          notesCount = notes.length;
          for (final row in notes) {
            batch.insert(
              'notes',
              Map<String, Object?>.from(row),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        // Handle Tags
        if (data.containsKey('tags')) {
          final List<dynamic> tags = data['tags'];
          tagsCount = tags.length;
          for (final row in tags) {
            batch.insert(
              'tags',
              Map<String, Object?>.from(row),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        // Handle Transactions (New in v2)
        if (data.containsKey('transactions')) {
          final List<dynamic> transactions = data['transactions'];
          transactionsCount = transactions.length;
          for (final row in transactions) {
            final map = Map<String, Object?>.from(row);
            // Remove _id to avoid conflicts with auto-increment keys
            // This ensures we don't overwrite existing transactions with same integers
            // but creates new entries instead.
            map.remove('_id');

            batch.insert(
              'transactions',
              map,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        await batch.commit(noResult: true);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restored: $notesCount notes, $tagsCount tags, $transactionsCount transactions',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Notify user to restart or refresh if needed, usually Provider updates handle UI
        // but explicit refresh might be good. For now, rely on standard navigation flow.
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
