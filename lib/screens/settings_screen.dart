import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
import '../utils/app_constants.dart';
import 'package:file_picker/file_picker.dart';
import 'app_lock_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/backup_service.dart';
import '../services/update_service.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/sms_import_sheet.dart';
import 'package:ota_update/ota_update.dart';

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
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                      const SizedBox(width: 8),
                      Text('Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.8),
                                        Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.4),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.settings_suggest_rounded,
                                          size: 28,
                                          color: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'System Settings',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Customize note styling, automated SMS rules, app security, and formats.',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SettingsSection(
                            title: 'App Features',
                            icon: Icons.apps_outlined,
                            children: [
                              SettingsSwitchTile(icon: Icons.account_balance_wallet_outlined, title: 'Financial Manager', subtitle: 'Enable expense tracking', value: settings.showFinancialManager, onChanged: settings.setShowFinancialManager),
                              if (settings.showFinancialManager) ...[
                                const _Divider(),
                                SettingsTile(icon: Icons.currency_exchange_outlined, title: 'Currency', subtitle: settings.currency, onTap: () => _showCurrencyPicker(context, settings)),
                                const _Divider(),
                                SettingsTile(icon: Icons.sms_outlined, title: 'Advanced SMS Import', subtitle: 'Fetch past bank transactions from messages', showArrow: true, onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const SmsImportSheet())),
                                const _Divider(),
                                SettingsTile(icon: Icons.category_outlined, title: 'Manage Categories', subtitle: 'Customise keywords and create new categories', showArrow: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementScreen()))),
                                const _Divider(),
                                SettingsTile(icon: Icons.contacts_outlined, title: 'SMS Contacts', subtitle: 'Manage bank & custom senders for auto-import', showArrow: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmsContactsScreen()))),
                                const _Divider(),
                                SettingsTile(icon: Icons.rule_folder_outlined, title: 'SMS Import Rules', subtitle: 'Manage auto-categorization and transaction type rules', showArrow: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmsRulesScreen()))),
                              ],
                              const _Divider(),
                              SettingsSwitchTile(icon: Icons.transform_rounded, title: 'Enable File Converter', subtitle: 'Show the compression utility in the bottom bar', value: settings.showFileConverter, onChanged: settings.setShowFileConverter),
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
                              SettingsTile(icon: Icons.label_outline, title: 'Manage Tags', subtitle: 'Rename or delete tags', showArrow: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageTagsScreen()))),
                              const _Divider(),
                              SettingsTile(icon: Icons.archive_outlined, title: 'Archive', subtitle: 'View archived notes', showArrow: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FilteredNotesScreen(filterType: FilterType.archived)))),
                              const _Divider(),
                              SettingsTile(icon: Icons.delete_outline, title: 'Trash', subtitle: 'View deleted notes', showArrow: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FilteredNotesScreen(filterType: FilterType.trash)))),
                            ],
                          ),
                          SettingsSection(
                            title: 'Privacy & Security',
                            icon: Icons.security_outlined,
                            children: [
                              SettingsSwitchTile(icon: Icons.calendar_month_outlined, title: 'Period Tracker', subtitle: 'Optional cycle tracking', value: settings.isPeriodTrackerEnabled, onChanged: settings.setIsPeriodTrackerEnabled),
                              if (settings.isPeriodTrackerEnabled) ...[
                                const _Divider(),
                                SettingsTile(icon: Icons.notifications_none_outlined, title: 'Discreet Notification Text', subtitle: settings.discreetNotificationText, onTap: () => _showNotificationTextDialog(context, settings)),
                              ],
                              const _Divider(),
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
                                      borderRadius: BorderRadius.circular(12),
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
                              SettingsTile(icon: FontAwesomeIcons.github, title: 'GitHub Repository', subtitle: 'View source code & contribute', trailing: Icon(Icons.open_in_new_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant), onTap: () => _launchUrl(AppConstants.repoUrl)),
                              const _Divider(),
                              FutureBuilder<PackageInfo>(
                                future: PackageInfo.fromPlatform(),
                                builder: (context, snapshot) {
                                  final version = snapshot.hasData ? 'v${snapshot.data!.version}+${snapshot.data!.buildNumber}' : 'Loading...';
                                  return SettingsTile(icon: Icons.info_outline_rounded, title: 'Version', subtitle: version, onTap: () => _launchUrl(AppConstants.releaseUrl));
                                },
                              ),
                              if (!kIsWeb && Platform.isAndroid) ...[
                                const _Divider(),
                                SettingsTile(
                                  icon: Icons.system_update_alt_rounded,
                                  title: 'Check for Updates',
                                  subtitle: 'Look for newer versions on GitHub',
                                  showArrow: true,
                                  onTap: () => _checkUpdates(context),
                                ),
                              ],
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
        title: const Text('Select Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppConstants.currencies.length,
            itemBuilder: (context, index) {
              final currency = AppConstants.currencies[index];
              // ignore: deprecated_member_use
              return RadioListTile<String>(title: Text(currency), value: currency, groupValue: settings.currency, onChanged: (v) { settings.setCurrency(v!); Navigator.pop(context); });
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

  void _checkUpdates(BuildContext context) async {
    unawaited(HapticFeedback.lightImpact());
    // Show a loading dialog
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Checking for updates...', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final updateInfo = await UpdateService.checkForUpdate();
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (updateInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App is up to date!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      _showUpdateDialog(context, updateInfo);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check for updates: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showUpdateDialog(BuildContext context, AppUpdateInfo updateInfo) {
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          double downloadProgress = 0.0;
          bool isDownloading = false;
          String errorMessage = '';

          return StatefulBuilder(
            builder: (context, setModalState) {
              final theme = Theme.of(context);

              void updateState(VoidCallback fn) {
                if (context.mounted) {
                  setModalState(fn);
                }
              }

              return PopScope(
                canPop: !isDownloading,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                },
                child: AlertDialog(
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.system_update_rounded,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Update Available',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Version v${updateInfo.version} is now available.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'What\'s New:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 160),
                        width: double.maxFinite,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            updateInfo.releaseNotes,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      if (errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (isDownloading) ...[
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: downloadProgress / 100.0,
                            minHeight: 8,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Downloading update...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${downloadProgress.toInt()}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: isDownloading ? null : () => Navigator.pop(context),
                      child: const Text('Later'),
                    ),
                    FilledButton(
                      onPressed: isDownloading
                          ? null
                          : () async {
                              unawaited(HapticFeedback.mediumImpact());
                              updateState(() {
                                isDownloading = true;
                                errorMessage = '';
                                downloadProgress = 0.0;
                              });

                              UpdateService.downloadAndInstall(updateInfo.downloadUrl).listen(
                                (OtaEvent event) {
                                  if (event.status == OtaStatus.DOWNLOADING) {
                                    final parsedVal = double.tryParse(event.value ?? '0') ?? 0.0;
                                    final progress = parsedVal > 1.0 ? parsedVal : parsedVal * 100.0;
                                    updateState(() {
                                      downloadProgress = progress;
                                    });
                                  } else if (event.status == OtaStatus.INSTALLING) {
                                    updateState(() {
                                      isDownloading = false;
                                    });
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  } else if (event.status == OtaStatus.ALREADY_RUNNING_ERROR) {
                                    updateState(() {
                                      isDownloading = false;
                                      errorMessage = 'An update is already running.';
                                    });
                                  } else if (event.status == OtaStatus.PERMISSION_NOT_GRANTED_ERROR) {
                                    updateState(() {
                                      isDownloading = false;
                                      errorMessage = 'Permission to install packages not granted.';
                                    });
                                  } else if (event.status == OtaStatus.INTERNAL_ERROR) {
                                    updateState(() {
                                      isDownloading = false;
                                      errorMessage = 'Internal error occurred during update.';
                                    });
                                  } else {
                                    updateState(() {
                                      isDownloading = false;
                                      errorMessage = 'Update failed: ${event.status}';
                                    });
                                  }
                                },
                                onError: (e) {
                                  updateState(() {
                                    isDownloading = false;
                                    errorMessage = 'Error: $e';
                                  });
                                },
                              );
                            },
                      child: const Text('Update Now'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Divider(height: 1, indent: 56, color: Theme.of(context).colorScheme.outlineVariant);
}
