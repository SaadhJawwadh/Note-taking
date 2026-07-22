import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'dart:async';
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';
import 'manage_tags_screen.dart';
import 'filtered_notes_screen.dart';
import 'category_management_screen.dart';
import 'sms_contacts_screen.dart';
import 'sms_rules_screen.dart';
import 'changelog_screen.dart';
import '../utils/app_constants.dart';
import '../utils/widget_helper.dart';
import '../utils/app_route.dart';
import '../theme/app_layout.dart';
import 'package:file_picker/file_picker.dart';
import 'app_lock_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/backup_service.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/sms_import_sheet.dart';
import '../widgets/recurring_rules_sheet.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return AnimationLimiter(
            child: CustomScrollView(
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
                    boxShadow: AppLayout.softShadow(context),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.settingsTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 220),
                            childAnimationBuilder: (widget) => SlideAnimation(verticalOffset: 24.0, child: FadeInAnimation(child: widget)),
                            children: [
                              SettingsSection(
                                title: 'Manage Features',
                                icon: Icons.apps_outlined,
                            children: [
                              SettingsSwitchTile(
                                icon: Icons.account_balance_wallet_outlined,
                                title: 'Financial Manager',
                                subtitle: 'Enable expense tracking',
                                value: settings.showFinancialManager,
                                onChanged: settings.setShowFinancialManager,
                              ),
                              const _Divider(),
                              SettingsSwitchTile(
                                icon: Icons.calendar_month_outlined,
                                title: 'Period Tracker',
                                subtitle: 'Optional cycle tracking',
                                value: settings.isPeriodTrackerEnabled,
                                onChanged: settings.setIsPeriodTrackerEnabled,
                              ),
                            ],
                          ),
                          if (settings.showFinancialManager)
                            SettingsSection(
                              title: 'Financial Manager Settings',
                              icon: Icons.wallet_outlined,
                              children: [
                                SettingsTile(icon: Icons.currency_exchange_outlined, title: 'Currency', subtitle: settings.currency, onTap: () => _showCurrencyPicker(context, settings)),
                                const _Divider(),
                                SettingsTile(icon: Icons.sms_outlined, title: 'Advanced SMS Import', subtitle: 'Fetch past bank transactions from messages', showArrow: true, onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const SmsImportSheet())),
                                const _Divider(),
                                SettingsTile(icon: Icons.category_outlined, title: 'Manage Categories', subtitle: 'Customise keywords and create new categories', showArrow: true, onTap: () => AppRoute.push(context, const CategoryManagementScreen())),
                                const _Divider(),
                                SettingsTile(icon: Icons.contacts_outlined, title: 'SMS Contacts', subtitle: 'Manage bank & custom senders for auto-import', showArrow: true, onTap: () => AppRoute.push(context, const SmsContactsScreen())),
                                const _Divider(),
                                SettingsTile(icon: Icons.event_repeat_outlined, title: 'Recurring Transactions', subtitle: 'Manage automatically repeating entries', showArrow: true, onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const RecurringRulesSheet())),
                                const _Divider(),
                                SettingsTile(icon: Icons.rule_folder_outlined, title: 'SMS Import Rules', subtitle: 'Manage auto-categorization and transaction type rules', showArrow: true, onTap: () => AppRoute.push(context, const SmsRulesScreen())),
                                const _Divider(),
                                SettingsSwitchTile(icon: Icons.sync_outlined, title: 'Daily SMS Auto-Sync', subtitle: 'Import bank transactions automatically daily', value: settings.dailySyncEnabled, onChanged: settings.setDailySyncEnabled),
                                if (settings.dailySyncEnabled) ...[
                                  const _Divider(),
                                  SettingsTile(icon: Icons.schedule_outlined, title: 'Auto-Sync Time', subtitle: _formatTimeOfDay(context, settings.dailySyncTime), onTap: () => _showTimePicker(context, settings)),
                                ],
                              ],
                            ),
                          if (settings.isPeriodTrackerEnabled)
                            SettingsSection(
                              title: 'Period Tracker Settings',
                              icon: Icons.calendar_today_outlined,
                              children: [
                                SettingsTile(icon: Icons.notifications_none_outlined, title: 'Discreet Notification Text', subtitle: settings.discreetNotificationText, onTap: () => _showNotificationTextDialog(context, settings)),
                              ],
                            ),
                          SettingsSection(
                            title: 'Privacy & Security',
                            icon: Icons.security_outlined,
                            children: [
                              SettingsSwitchTile(icon: Icons.lock_outline, title: 'App Lock', subtitle: 'Require authentication to open app', value: settings.appLockEnabled, onChanged: settings.setAppLockEnabled),
                              if (settings.appLockEnabled) ...[
                                const _Divider(),
                                SettingsSwitchTile(
                                  icon: Icons.fingerprint_outlined,
                                  title: 'Use Biometrics',
                                  subtitle: 'Require biometric scan specifically',
                                  value: settings.useBiometrics,
                                  onChanged: settings.setUseBiometrics,
                                ),
                                const _Divider(),
                                SettingsTile(
                                  icon: Icons.timer_outlined,
                                  title: 'Auto-Lock Timeout',
                                  subtitle: _getTimeoutLabel(settings.appLockTimeout),
                                  showArrow: true,
                                  onTap: () => _showTimeoutPicker(context, settings),
                                ),
                              ],
                            ],
                          ),
                          SettingsSection(
                            title: 'Appearance & UI',
                            icon: Icons.palette_outlined,
                            children: [
                              SettingsTile(icon: Icons.palette_outlined, title: 'Theme', subtitle: _getThemeLabel(settings.themeMode), onTap: () => _showThemePicker(context, settings)),
                              const _Divider(),
                              SettingsTile(icon: Icons.text_fields, title: 'Text Size', subtitle: settings.textSizeLabel, onTap: () => _showTextSizePicker(context, settings)),
                            ],
                          ),
                          SettingsSection(
                            title: 'Organization & Folders',
                            icon: Icons.folder_open_outlined,
                            children: [
                              SettingsTile(icon: Icons.label_outline, title: 'Manage Tags', subtitle: 'Rename or delete tags', showArrow: true, onTap: () => AppRoute.push(context, const ManageTagsScreen())),
                              const _Divider(),
                              SettingsTile(icon: Icons.archive_outlined, title: 'Archive', subtitle: 'View archived notes', showArrow: true, onTap: () => AppRoute.push(context, const FilteredNotesScreen(filterType: FilterType.archived))),
                              const _Divider(),
                              SettingsTile(icon: Icons.delete_outline, title: 'Trash', subtitle: 'View deleted notes', showArrow: true, onTap: () => AppRoute.push(context, const FilteredNotesScreen(filterType: FilterType.trash))),
                            ],
                          ),
                          SettingsSection(
                            title: 'Local AI Features',
                            icon: Icons.psychology_outlined,
                            children: [
                              if (settings.isDeviceAiSupported)
                                SettingsSwitchTile(
                                  icon: Icons.auto_awesome_outlined,
                                  title: 'Gemini Nano AI',
                                  subtitle: 'Enable offline summaries, tag suggestions & smart SMS parsing',
                                  value: settings.useOnDeviceAi,
                                  onChanged: settings.setUseOnDeviceAi,
                                )
                              else
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(AppLayout.radiusM),
                                    ),
                                    child: const Icon(Icons.auto_awesome_outlined, size: 20, color: Colors.grey),
                                  ),
                                  title: const Text(
                                    'Gemini Nano Offline AI',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Unsupported on this device (requires compatible NPU and Android AI Core)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.info_outline, color: Colors.grey),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                ),
                            ],
                          ),
                          SettingsSection(
                            title: 'Data & Backup',
                            icon: Icons.cloud_sync_outlined,
                            children: [
                              SettingsTile(icon: Icons.download_outlined, title: 'Export Backup', subtitle: 'Save notes to a JSON file', showArrow: true, onTap: () => BackupService.exportBackup(context)),
                              const _Divider(),
                              SettingsTile(icon: Icons.upload_outlined, title: 'Import Backup', subtitle: 'Restore from a JSON file', showArrow: true, onTap: () => BackupService.importBackup(context)),
                              if (!kIsWeb && Platform.isAndroid) ...[
                                const _Divider(),
                                SettingsSwitchTile(
                                  icon: Icons.backup_outlined,
                                  title: 'Auto Backup',
                                  subtitle: 'Schedule automatic backups',
                                  value: settings.autoBackupEnabled,
                                  onChanged: (value) async {
                                    if (value) {
                                      AppLockScreen.ignoreNextResumeLock();
                                      final dir = await FilePicker.platform.getDirectoryPath();
                                      if (dir == null) return;
                                      await settings.setAutoBackupPath(dir);
                                    }
                                    await settings.setAutoBackupEnabled(value);
                                    await syncAutoBackupSchedule();
                                  },
                                ),
                                if (settings.autoBackupEnabled) ...[
                                  const _Divider(),
                                  SettingsTile(icon: Icons.schedule_outlined, title: 'Backup Frequency', subtitle: _getFrequencyLabel(settings.autoBackupFrequency), onTap: () => _showFrequencyPicker(context, settings)),
                                  const _Divider(),
                                  SettingsTile(
                                    icon: Icons.folder_outlined,
                                    title: 'Backup Location',
                                    subtitle: settings.autoBackupPath ?? 'App default directory',
                                    onTap: () async {
                                      AppLockScreen.ignoreNextResumeLock();
                                      final dir = await FilePicker.platform.getDirectoryPath();
                                      if (dir != null) {
                                        await settings.setAutoBackupPath(dir);
                                        await syncAutoBackupSchedule();
                                      }
                                    },
                                  ),
                                  if (settings.lastAutoBackupTime != null) ...[
                                    const _Divider(),
                                    SettingsTile(icon: Icons.history_outlined, title: 'Last Auto Backup', subtitle: _formatLastBackupTime(settings.lastAutoBackupTime!)),
                                  ],
                                ],
                              ],
                            ],
                          ),

                          SettingsSection(
                            title: 'About',
                            icon: Icons.info_outline_rounded,
                            children: [
                              SettingsTile(
                                icon: Icons.star_outline_rounded,
                                title: 'Rate & Feedback',
                                subtitle: 'Love the app? Rate us on the Play Store',
                                trailing: Icon(Icons.open_in_new_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                onTap: () => _launchUrl('https://play.google.com/store/apps/details?id=com.saadhjawwadh.notebook'),
                              ),
                              const _Divider(),
                              SettingsTile(
                                icon: Icons.history_rounded,
                                title: 'Changelog',
                                subtitle: 'View version release logs',
                                showArrow: true,
                                onTap: () => AppRoute.push(context, const ChangelogScreen()),
                              ),
                              const _Divider(),
                              FutureBuilder<PackageInfo>(
                                future: PackageInfo.fromPlatform(),
                                builder: (context, snapshot) {
                                  final version = snapshot.hasData ? 'v${snapshot.data!.version}+${snapshot.data!.buildNumber}' : 'Loading...';
                                  return SettingsTile(icon: Icons.info_outline_rounded, title: 'Version', subtitle: version, onTap: () => _launchUrl(AppConstants.releaseUrl));
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
      case ThemeMode.system: return 'System Default';
    }
  }

  void _showThemePicker(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ignore: deprecated_member_use
            RadioListTile<ThemeMode>(title: const Text('System Default'), value: ThemeMode.system, groupValue: settings.themeMode, onChanged: (v) { settings.setThemeMode(v!); Navigator.pop(context); }),
            // ignore: deprecated_member_use
            RadioListTile<ThemeMode>(title: const Text('Light'), value: ThemeMode.light, groupValue: settings.themeMode, onChanged: (v) { settings.setThemeMode(v!); Navigator.pop(context); }),
            // ignore: deprecated_member_use
            RadioListTile<ThemeMode>(title: const Text('Dark'), value: ThemeMode.dark, groupValue: settings.themeMode, onChanged: (v) { settings.setThemeMode(v!); Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }

  void _showTextSizePicker(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: const Text('Text Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ignore: deprecated_member_use
            RadioListTile<double>(title: const Text('Small'), value: 14.0, groupValue: settings.textSize, onChanged: (v) { settings.setTextSize(v!); Navigator.pop(context); }),
            // ignore: deprecated_member_use
            RadioListTile<double>(title: const Text('Medium'), value: 16.0, groupValue: settings.textSize, onChanged: (v) { settings.setTextSize(v!); Navigator.pop(context); }),
            // ignore: deprecated_member_use
            RadioListTile<double>(title: const Text('Large'), value: 20.0, groupValue: settings.textSize, onChanged: (v) { settings.setTextSize(v!); Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: const Text('Select Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppConstants.currencies.length,
            itemBuilder: (context, index) {
              final currency = AppConstants.currencies[index];
              // ignore: deprecated_member_use
              return RadioListTile<String>(title: Text(currency), value: currency, groupValue: settings.currency, onChanged: (v) { settings.setCurrency(v!); WidgetHelper.updateWidgetData(); Navigator.pop(context); });
            },
          ),
        ),
      ),
    );
  }

  void _showNotificationTextDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.discreetNotificationText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: const Text('Discreet Notification'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'e.g., Check the app', labelText: 'Alert Text')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () { if (controller.text.trim().isNotEmpty) settings.setDiscreetNotificationText(controller.text.trim()); Navigator.pop(context); }, child: const Text('Save')),
        ],
      ),
    );
  }

  String _getFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'weekly': return 'Weekly';
      case 'monthly': return 'Monthly';
      default: return 'Daily';
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
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: const Text('Backup Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ignore: deprecated_member_use
            RadioListTile<String>(title: const Text('Daily'), value: 'daily', groupValue: settings.autoBackupFrequency, onChanged: (v) async { 
              await settings.setAutoBackupFrequency(v!); 
              await syncAutoBackupSchedule(); 
              if (context.mounted) Navigator.pop(context); 
            }),
            // ignore: deprecated_member_use
            RadioListTile<String>(title: const Text('Weekly'), value: 'weekly', groupValue: settings.autoBackupFrequency, onChanged: (v) async { 
              await settings.setAutoBackupFrequency(v!); 
              await syncAutoBackupSchedule(); 
              if (context.mounted) Navigator.pop(context); 
            }),
            // ignore: deprecated_member_use
            RadioListTile<String>(title: const Text('Monthly'), value: 'monthly', groupValue: settings.autoBackupFrequency, onChanged: (v) async { 
              await settings.setAutoBackupFrequency(v!); 
              await syncAutoBackupSchedule(); 
              if (context.mounted) Navigator.pop(context); 
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    AppLockScreen.ignoreNextResumeLock();
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) throw Exception('Could not launch $url');
  }



  String _getTimeoutLabel(int seconds) {
    if (seconds == 0) return 'Immediately';
    if (seconds < 60) return '$seconds seconds';
    return '${seconds ~/ 60} minute${seconds >= 120 ? "s" : ""}';
  }

  void _showTimeoutPicker(BuildContext context, SettingsProvider settings) {
    final options = {
      0: 'Immediately',
      10: '10 seconds',
      30: '30 seconds',
      60: '1 minute',
      300: '5 minutes',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: const Text('Auto-Lock Timeout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.entries.map((entry) {
            return RadioListTile<int>(
              title: Text(entry.value),
              value: entry.key,
              // ignore: deprecated_member_use
              groupValue: settings.appLockTimeout,
              // ignore: deprecated_member_use
              onChanged: (v) {
                settings.setAppLockTimeout(v!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatTimeOfDay(BuildContext context, String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final time = TimeOfDay(hour: hour, minute: minute);
      return time.format(context);
    } catch (_) {
      return timeStr;
    }
  }

  void _showTimePicker(BuildContext context, SettingsProvider settings) async {
    final parts = settings.dailySyncTime.split(':');
    final initialHour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 20 : 20;
    final initialMinute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await settings.setDailySyncTime(formattedTime);
    }
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Divider(height: 1, indent: 56, color: Theme.of(context).colorScheme.outlineVariant);
}
