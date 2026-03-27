import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';
import 'manage_tags_screen.dart';
import 'filtered_notes_screen.dart';
import 'category_management_screen.dart';
import 'sms_contacts_screen.dart';
import '../utils/app_constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/backup_service.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/sms_import_sheet.dart';

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
                          SettingsSection(
                            title: 'Finances & Features',
                            icon: Icons.account_balance_wallet_outlined,
                            initiallyExpanded: true,
                            children: [
                              SettingsSwitchTile(icon: Icons.account_balance_wallet_outlined, title: 'Financial Manager', subtitle: 'Enable expense tracking', value: settings.showFinancialManager, onChanged: settings.setShowFinancialManager),
                              if (settings.showFinancialManager) ...[
                                const _Divider(),
                                SettingsTile(icon: Icons.currency_exchange_outlined, title: 'Currency', subtitle: settings.currency, onTap: () => _showCurrencyPicker(context, settings)),
                                const _Divider(),
                                SettingsTile(icon: Icons.sms_outlined, title: 'Advanced SMS Import', subtitle: 'Fetch past bank transactions from messages', showArrow: true, onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const SmsImportSheet())),
                                const _Divider(),
                                SettingsTile(icon: Icons.category_outlined, title: 'Manage Categories', subtitle: 'Customise keywords and create new categories', showArrow: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementScreen()))),
                                const _Divider(),
                                SettingsTile(icon: Icons.contacts_outlined, title: 'SMS Contacts', subtitle: 'Manage bank & custom senders for auto-import', showArrow: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmsContactsScreen()))),
                              ]
                            ],
                          ),
                          SettingsSection(
                            title: 'Standalone Utilities',
                            icon: Icons.api_outlined,
                            children: [
                              SettingsSwitchTile(icon: Icons.transform_rounded, title: 'Enable File Converter', subtitle: 'Show the compression utility in the bottom bar', value: settings.showFileConverter, onChanged: settings.setShowFileConverter),
                              if (settings.showFileConverter) ...[
                                const _Divider(),
                                SettingsSwitchTile(
                                  icon: Icons.bolt_outlined, 
                                  title: 'Converter Lite Mode', 
                                  subtitle: settings.isConverterLite 
                                    ? 'Using lightweight native tools (No FFmpeg needed)' 
                                    : 'Using high-performance FFmpeg engine', 
                                  value: settings.isConverterLite, 
                                  onChanged: settings.setIsConverterLite,
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
                              SettingsTile(icon: Icons.label_outline, title: 'Manage Tags', subtitle: 'Rename or delete tags', showArrow: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageTagsScreen()))),
                              const _Divider(),
                              SettingsTile(icon: Icons.archive_outlined, title: 'Archive', subtitle: 'View archived notes', showArrow: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FilteredNotesScreen(filterType: FilterType.archived)))),
                              const _Divider(),
                              SettingsTile(icon: Icons.delete_outline, title: 'Trash', subtitle: 'View deleted notes', showArrow: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FilteredNotesScreen(filterType: FilterType.trash)))),
                            ],
                          ),
                          SettingsSection(
                            title: 'Privacy & Personal',
                            icon: Icons.security_outlined,
                            children: [
                              SettingsSwitchTile(icon: Icons.calendar_month_outlined, title: 'Period Tracker', subtitle: 'Optional cycle tracking', value: settings.isPeriodTrackerEnabled, onChanged: settings.setIsPeriodTrackerEnabled),
                              if (settings.isPeriodTrackerEnabled) ...[
                                const _Divider(),
                                SettingsTile(icon: Icons.notifications_none_outlined, title: 'Discreet Notification Text', subtitle: settings.discreetNotificationText, onTap: () => _showNotificationTextDialog(context, settings)),
                              ],
                              const _Divider(),
                              SettingsSwitchTile(icon: Icons.lock_outline, title: 'App Lock', subtitle: 'Require authentication to open app', value: settings.appLockEnabled, onChanged: settings.setAppLockEnabled),
                            ],
                          ),
                          SettingsSection(
                            title: 'Data & Backup',
                            icon: Icons.cloud_sync_outlined,
                            children: [
                              SettingsTile(icon: Icons.download_outlined, title: 'Export Backup', subtitle: 'Save notes to a JSON file', showArrow: true, onTap: () => BackupService.exportBackup(context)),
                              const _Divider(),
                              SettingsTile(icon: Icons.upload_outlined, title: 'Import Backup', subtitle: 'Restore from a JSON file', showArrow: true, onTap: () => BackupService.importBackup(context)),
                              if (Platform.isAndroid) ...[
                                const _Divider(),
                                SettingsSwitchTile(
                                  icon: Icons.backup_outlined,
                                  title: 'Auto Backup',
                                  subtitle: 'Schedule automatic backups',
                                  value: settings.autoBackupEnabled,
                                  onChanged: (value) async {
                                    if (value) {
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
                            title: 'File Converter Settings',
                            icon: Icons.transform_rounded,
                            children: [
                              if (settings.isConverterLite) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Text(
                                    'Lite Mode uses native tools. Video compression is restricted to format conversion only.',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                                  ),
                                ),
                                const _Divider(),
                              ],
                              SettingsTile(icon: Icons.video_collection_outlined, title: 'Preferred Video Format', subtitle: settings.preferredVideoFormat.toUpperCase(), onTap: () => _showFormatPicker(context, settings, 'Video', ['mp4', 'mkv', 'gif'], settings.preferredVideoFormat, settings.setPreferredVideoFormat)),
                              const _Divider(),
                              SettingsTile(icon: Icons.image_outlined, title: 'Preferred Image Format', subtitle: settings.preferredImageFormat.toUpperCase(), onTap: () => _showFormatPicker(context, settings, 'Image', ['jpg', 'png', 'webp'], settings.preferredImageFormat, settings.setPreferredImageFormat)),
                              const _Divider(),
                              SettingsTile(icon: Icons.photo_size_select_large_outlined, title: 'Video Resolution Limit', subtitle: settings.videoResolutionLimit, onTap: () => _showFormatPicker(context, settings, 'Resolution Limit', ['Original', '1080p', '720p', '480p'], settings.videoResolutionLimit, settings.setVideoResolutionLimit)),
                              const _Divider(),
                              SettingsSwitchTile(icon: Icons.info_outline_rounded, title: 'Keep Metadata', subtitle: 'Maintain EXIF and device info', value: settings.keepMetadata, onChanged: settings.setKeepMetadata),
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

  void _showFormatPicker(BuildContext context, SettingsProvider settings, String title, List<String> options, String currentValue, Function(String) onSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: Text('Select $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          // ignore: deprecated_member_use
          children: options.map((option) => RadioListTile<String>(title: Text(option.toUpperCase()), value: option, groupValue: currentValue, onChanged: (v) { onSelected(v!); Navigator.pop(context); })).toList(),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Divider(height: 1, indent: 56, color: Theme.of(context).colorScheme.outlineVariant);
}
