// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:package_info_plus/package_info_plus.dart';

import 'dart:convert';
import 'dart:io';

import 'package:sqflite_sqlcipher/sqflite.dart';
import '../data/database_helper.dart';
import '../data/sms_contact.dart';
import '../data/transaction_category.dart';

import 'package:provider/provider.dart';
import '../data/settings_provider.dart';

import 'manage_tags_screen.dart';
import 'filtered_notes_screen.dart';
import 'category_management_screen.dart';
import 'sms_whitelist_screen.dart'; // SmsContactsScreen lives here
import '../utils/app_constants.dart';

import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/sms_service.dart';
import '../services/backup_service.dart';

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
                titleSpacing: 16,
                automaticallyImplyLeading: false,
                title: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  height: 64,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        duration: const Duration(milliseconds: 220),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 24.0,
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
                              Divider(
                                height: 1,
                                indent: 56,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              _buildListTile(
                                context,
                                icon: Icons.sms_outlined,
                                title: 'Import SMS Transactions',
                                subtitle:
                                    'Fetch bank transactions from messages',
                                showArrow: true,
                                onTap: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const _SmsImportSheet(),
                                ),
                              ),
                              Divider(
                                height: 1,
                                indent: 56,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              _buildListTile(
                                context,
                                icon: Icons.category_outlined,
                                title: 'Manage Categories',
                                subtitle:
                                    'Customise keywords and create new categories',
                                showArrow: true,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CategoryManagementScreen(),
                                  ),
                                ),
                              ),
                              Divider(
                                height: 1,
                                indent: 56,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              _buildListTile(
                                context,
                                icon: Icons.contacts_outlined,
                                title: 'SMS Contacts',
                                subtitle:
                                    'Manage bank & custom senders for auto-import',
                                showArrow: true,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SmsContactsScreen(),
                                  ),
                                ),
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
                          _buildSectionHeader(context, 'PERIOD & PRIVACY'),
                          _buildSettingsContainer(context, [
                            _buildSwitchTile(
                              context,
                              icon: Icons.calendar_month_outlined,
                              title: 'Period Tracker',
                              subtitle: 'Optional cycle tracking',
                              value: settings.isPeriodTrackerEnabled,
                              onChanged: (value) =>
                                  settings.setIsPeriodTrackerEnabled(value),
                            ),
                            if (settings.isPeriodTrackerEnabled) ...[
                              Divider(
                                height: 1,
                                indent: 56,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              _buildListTile(
                                context,
                                icon: Icons.notifications_none_outlined,
                                title: 'Discreet Notification Text',
                                subtitle: settings.discreetNotificationText,
                                onTap: () => _showNotificationTextDialog(
                                    context, settings),
                              ),
                            ],
                            Divider(
                              height: 1,
                              indent: 56,
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                            _buildSwitchTile(
                              context,
                              icon: Icons.lock_outline,
                              title: 'App Lock',
                              subtitle: 'Require authentication to open app',
                              value: settings.appLockEnabled,
                              onChanged: (value) async {
                                // If enabling, we might want to check if hardware supports it, but local_auth handles it.
                                await settings.setAppLockEnabled(value);
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
                            if (Platform.isAndroid) ...[
                              Divider(
                                height: 1,
                                indent: 56,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              _buildSwitchTile(
                                context,
                                icon: Icons.backup_outlined,
                                title: 'Auto Backup',
                                subtitle: 'Schedule automatic backups',
                                value: settings.autoBackupEnabled,
                                onChanged: (value) async {
                                  if (value) {
                                    final dir = await FilePicker.platform
                                        .getDirectoryPath();
                                    if (dir == null) return;
                                    await settings.setAutoBackupPath(dir);
                                  }
                                  await settings.setAutoBackupEnabled(value);
                                  await syncAutoBackupSchedule();
                                },
                              ),
                              if (settings.autoBackupEnabled) ...[
                                Divider(
                                  height: 1,
                                  indent: 56,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                                _buildListTile(
                                  context,
                                  icon: Icons.schedule_outlined,
                                  title: 'Backup Frequency',
                                  subtitle: _getFrequencyLabel(
                                      settings.autoBackupFrequency),
                                  onTap: () =>
                                      _showFrequencyPicker(context, settings),
                                ),
                                Divider(
                                  height: 1,
                                  indent: 56,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                                _buildListTile(
                                  context,
                                  icon: Icons.folder_outlined,
                                  title: 'Backup Location',
                                  subtitle: settings.autoBackupPath ??
                                      'App default directory',
                                  onTap: () async {
                                    final dir = await FilePicker.platform
                                        .getDirectoryPath();
                                    if (dir != null) {
                                      await settings.setAutoBackupPath(dir);
                                      await syncAutoBackupSchedule();
                                    }
                                  },
                                ),
                                if (settings.lastAutoBackupTime != null) ...[
                                  Divider(
                                    height: 1,
                                    indent: 56,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                  ),
                                  _buildListTile(
                                    context,
                                    icon: Icons.history_outlined,
                                    title: 'Last Auto Backup',
                                    subtitle: _formatLastBackupTime(
                                        settings.lastAutoBackupTime!),
                                  ),
                                ],
                              ],
                            ],
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

  void _showNotificationTextDialog(
      BuildContext context, SettingsProvider settings) {
    final TextEditingController controller =
        TextEditingController(text: settings.discreetNotificationText);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discreet Notification'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'e.g., Check the app',
              labelText: 'Alert Text',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  settings.setDiscreetNotificationText(controller.text.trim());
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
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

  // ── Auto-backup helpers ──────────────────────────────────────────────────

  String _getFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'daily':
      default:
        return 'Daily';
    }
  }

  String _formatLastBackupTime(String isoTime) {
    final dt = DateTime.tryParse(isoTime);
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} minutes ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  void _showFrequencyPicker(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          title: Text(
            'Backup Frequency',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(
                  'Daily',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                value: 'daily',
                groupValue: settings.autoBackupFrequency,
                onChanged: (value) async {
                  await settings.setAutoBackupFrequency(value!);
                  await syncAutoBackupSchedule();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: Text(
                  'Weekly',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                value: 'weekly',
                groupValue: settings.autoBackupFrequency,
                onChanged: (value) async {
                  await settings.setAutoBackupFrequency(value!);
                  await syncAutoBackupSchedule();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: Text(
                  'Monthly',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                value: 'monthly',
                groupValue: settings.autoBackupFrequency,
                onChanged: (value) async {
                  await settings.setAutoBackupFrequency(value!);
                  await syncAutoBackupSchedule();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);

      final db = await DatabaseHelper.instance.database;
      final notes = await db.query('notes');
      final tags = await db.query('tags');
      final transactions = await db.query('transactions');
      final categoryDefinitions = await db.query('category_definitions');
      final smsContacts = await db.query('sms_contacts');

      final backupData = {
        'notes': notes,
        'tags': tags,
        'transactions': transactions,
        'categoryDefinitions': categoryDefinitions,
        'smsContacts': smsContacts,
        'settings': settings.toBackupMap(),
        'version': 6,
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
        final dynamic decoded = jsonDecode(content);

        // Handle legacy format (root-level list of notes)
        final Map<String, dynamic> data = decoded is List
            ? {'notes': decoded}
            : Map<String, dynamic>.from(decoded as Map);

        // Preview counts for confirmation dialog
        final previewNotes = (data['notes'] as List?)?.length ?? 0;
        final previewTags = (data['tags'] as List?)?.length ?? 0;
        final previewTransactions =
            (data['transactions'] as List?)?.length ?? 0;
        final previewCategories =
            (data['categoryDefinitions'] as List?)?.where((c) {
                  final m = c as Map;
                  return (m['isBuiltIn'] as int? ?? 1) == 0;
                }).length ??
                0;
        final previewWhitelist = (data['smsContacts'] as List?)?.length ??
            (data['smsWhitelist'] as List?)?.length ??
            0;
        final previewVersion = data['version'] ?? 1;

        if (!context.mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Backup?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Backup version: $previewVersion'),
                const SizedBox(height: 8),
                Text('$previewNotes notes'),
                Text('$previewTags tags'),
                Text('$previewTransactions transactions'),
                if (previewCategories > 0)
                  Text('$previewCategories custom categories'),
                if (previewWhitelist > 0)
                  Text('$previewWhitelist SMS contact(s)'),
                const SizedBox(height: 12),
                Text(
                  'Existing notes and tags with the same ID will be overwritten. '
                  'Duplicate transactions will be skipped.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Import'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

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

        // Handle Transactions — deduplicate by content fingerprint
        if (data.containsKey('transactions')) {
          final List<dynamic> transactions = data['transactions'];

          // Build set of existing fingerprints to prevent duplicates
          final existingRows = await db.query(
            'transactions',
            columns: ['amount', 'description', 'date', 'isExpense'],
          );
          final existingFingerprints = existingRows.map((row) {
            final dateKey = (row['date'] as String).substring(0, 10);
            return '${row['amount']}|${row['description']}|$dateKey|${row['isExpense']}';
          }).toSet();

          for (final row in transactions) {
            final map = Map<String, Object?>.from(row);
            map.remove('_id');

            final dateKey = (map['date'] as String? ?? '').substring(0, 10);
            final fingerprint =
                '${map['amount']}|${map['description']}|$dateKey|${map['isExpense']}';

            if (!existingFingerprints.contains(fingerprint)) {
              batch.insert(
                'transactions',
                map,
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
              transactionsCount++;
              existingFingerprints.add(fingerprint);
            }
          }
        }

        await batch.commit(noResult: true);

        // Restore custom category definitions (v4+ backups only)
        // Built-in categories are seeded by DB migrations; only custom ones
        // need restoring. We use replace so keyword edits carry over too.
        if (data.containsKey('categoryDefinitions')) {
          final List<dynamic> cats = data['categoryDefinitions'] as List;
          final db2 = await DatabaseHelper.instance.database;
          for (final row in cats) {
            final map = Map<String, Object?>.from(row as Map);
            // Custom categories: replace to restore user's keywords/colours.
            // Built-in categories: ignore — DB migrations own their lifecycle.
            final isBuiltIn = (map['isBuiltIn'] as int? ?? 0) == 1;
            await db2.insert(
              'category_definitions',
              map,
              conflictAlgorithm: isBuiltIn
                  ? ConflictAlgorithm.ignore
                  : ConflictAlgorithm.replace,
            );
          }
          await TransactionCategory.reload();
        }

        // Restore SMS contacts (v6+ backups) or legacy whitelist (v5 backups)
        if (data.containsKey('smsContacts')) {
          final List<dynamic> contacts = data['smsContacts'] as List;
          final db3 = await DatabaseHelper.instance.database;
          for (final row in contacts) {
            final map = Map<String, Object?>.from(row as Map);
            await db3.insert(
              'sms_contacts',
              map,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
          await SmsService.reloadSmsContacts();
        } else if (data.containsKey('smsWhitelist')) {
          // v5 backup: migrate old whitelist entries as custom contacts
          final List<dynamic> whitelist = data['smsWhitelist'] as List;
          for (final row in whitelist) {
            final map = Map<String, Object?>.from(row as Map);
            final sender = map['sender'] as String? ?? '';
            if (sender.isEmpty) continue;
            await DatabaseHelper.instance.upsertSmsContact(SmsContact(
              id: 'custom_${sender.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}',
              senderIds: [sender],
              label: sender,
            ));
          }
          await SmsService.reloadSmsContacts();
        }

        // Restore settings if present (v3+ backups)
        if (context.mounted &&
            data.containsKey('settings') &&
            data['settings'] is Map) {
          final settingsProvider =
              Provider.of<SettingsProvider>(context, listen: false);
          await settingsProvider.restoreFromBackupMap(
              Map<String, dynamic>.from(data['settings'] as Map));
        }

        if (!context.mounted) return;
        final categoryMsg =
            previewCategories > 0 ? ', $previewCategories categories' : '';
        final whitelistMsg =
            previewWhitelist > 0 ? ', $previewWhitelist SMS contacts' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restored: $notesCount notes, $tagsCount tags, '
              '$transactionsCount transactions$categoryMsg$whitelistMsg',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
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

// ── SMS Import bottom sheet ──────────────────────────────────────────────────

class _SmsImportSheet extends StatefulWidget {
  const _SmsImportSheet();

  @override
  State<_SmsImportSheet> createState() => _SmsImportSheetState();
}

class _SmsImportSheetState extends State<_SmsImportSheet> {
  // Period options: label + offset in days (null = all time)
  static const _periods = [
    ('Last day', 1),
    ('Last 7 days', 7),
    ('Last 30 days', 30),
    ('Last 3 months', 90),
    ('All time', null),
  ];

  int _selectedIndex = 2; // default: Last 30 days
  bool _loading = false;

  Future<void> _runImport() async {
    final granted = await SmsService.hasPermission();
    if (!mounted) return;

    if (!granted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('SMS Access'),
          content: const Text(
            'This app needs permission to read your SMS messages '
            'so it can detect and import bank transactions.\n\n'
            'Only messages from recognised bank senders are processed. '
            'No messages are sent off-device or shared.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Allow'),
            ),
          ],
        ),
      );
      if (proceed != true) return;

      final ok = await SmsService.requestPermissions();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS permission is required to import transactions.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _loading = true);

    final offsetDays = _periods[_selectedIndex].$2;
    final from = offsetDays != null
        ? DateTime.now().subtract(Duration(days: offsetDays))
        : DateTime(2000); // effectively "all time"

    final count = await SmsService.syncInboxFrom(from);

    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 0
              ? 'No new transactions found.'
              : 'Imported $count new transaction${count == 1 ? '' : 's'} from SMS.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Import SMS Transactions',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Choose how far back to scan your SMS inbox for bank transactions.',
            style: textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          // Period selector
          ...List.generate(_periods.length, (i) {
            final (label, _) = _periods[i];
            return RadioListTile<int>(
              title: Text(label),
              value: i,
              groupValue: _selectedIndex,
              onChanged:
                  _loading ? null : (v) => setState(() => _selectedIndex = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }),
          const SizedBox(height: 20),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _loading ? null : _runImport,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined, size: 18),
                label: Text(_loading ? 'Importing…' : 'Import'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
