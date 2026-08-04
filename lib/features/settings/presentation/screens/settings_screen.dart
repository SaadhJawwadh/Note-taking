import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'package:note_taking_app/features/notes/presentation/screens/manage_tags_screen.dart';
import 'package:note_taking_app/features/notes/presentation/screens/filtered_notes_screen.dart';
import 'package:note_taking_app/features/finances/presentation/screens/category_management_screen.dart';
import 'package:note_taking_app/features/finances/presentation/screens/sms_contacts_screen.dart';
import 'package:note_taking_app/features/finances/presentation/screens/sms_rules_screen.dart';
import 'package:note_taking_app/features/sync/presentation/screens/p2p_sync_screen.dart';
import '../../../../screens/changelog_screen.dart';
import 'onboarding_screen.dart';
import '../../../../utils/app_constants.dart';
import '../../../../utils/widget_helper.dart';
import '../../../../utils/app_route.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../core/ui/frosted_sliver_app_bar.dart';
import '../../../../core/ui/app_bottom_sheet.dart';
import '../../../../core/ui/app_chip.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../screens/app_lock_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/backup_service.dart';
import '../../../../services/sms_service.dart';
import '../../../../widgets/settings_widgets.dart';
import '../../../../widgets/sms_import_sheet.dart';
import '../../../../widgets/recurring_rules_sheet.dart';
import '../../../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  final String? initialQuery;

  const SettingsScreen({
    super.key,
    this.initialQuery,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _searchController;
  late String _searchQuery;
  String _selectedSearchCategory = 'All';

  final List<String> _searchCategories = [
    'All',
    'Finances',
    'Security',
    'Appearance',
    'Data & Backup',
    'Notes & Tags',
  ];

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: _searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTrashPurgeDialog(BuildContext context, SettingsProvider settings) {
    final options = [
      (label: '7 Days', days: 7, desc: 'Auto-delete items 7 days old'),
      (label: '14 Days', days: 14, desc: 'Auto-delete items 14 days old'),
      (label: '30 Days (Default)', days: 30, desc: 'Auto-delete items 30 days old'),
      (label: 'Disabled', days: 0, desc: 'Never auto-delete deleted notes'),
    ];

    AppBottomSheet.show(
      context: context,
      title: 'Trash Auto-Purge Duration',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = settings.trashAutoPurgeDays == opt.days;
          final colorScheme = Theme.of(context).colorScheme;

          return Material(
            color: Colors.transparent,
            child: ListTile(
              leading: Icon(
                Icons.auto_delete_outlined,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              title: Text(
                opt.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                opt.desc,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                  : null,
              onTap: () {
                HapticFeedback.selectionClick();
                settings.setTrashAutoPurgeDays(opt.days);
                Navigator.pop(context);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showThemePicker(BuildContext context, SettingsProvider settings) {
    final options = [
      (label: 'System Default', mode: ThemeMode.system, icon: Icons.brightness_auto_rounded, desc: 'Follow device dark mode settings'),
      (label: 'Light Theme', mode: ThemeMode.light, icon: Icons.light_mode_rounded, desc: 'Clean high-contrast light mode'),
      (label: 'Dark Theme', mode: ThemeMode.dark, icon: Icons.dark_mode_rounded, desc: 'Sleek dark mode surface theme'),
    ];

    AppBottomSheet.show(
      context: context,
      title: 'Choose Theme',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = settings.themeMode == opt.mode;
          final colorScheme = Theme.of(context).colorScheme;

          return ListTile(
            leading: Icon(
              opt.icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            title: Text(
              opt.label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              opt.desc,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                : null,
            onTap: () {
              HapticFeedback.selectionClick();
              settings.setThemeMode(opt.mode);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showTextSizePicker(BuildContext context, SettingsProvider settings) {
    final options = [
      (label: 'Small (14px)', size: 14.0, desc: 'Compact font size for maximum content density'),
      (label: 'Medium (16px)', size: 16.0, desc: 'Standard readable typography scale'),
      (label: 'Large (20px)', size: 20.0, desc: 'Large high-legibility font scale'),
    ];

    AppBottomSheet.show(
      context: context,
      title: 'Choose Text Scale',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = settings.textSize == opt.size;
          final colorScheme = Theme.of(context).colorScheme;

          return ListTile(
            leading: Icon(
              Icons.text_fields,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            title: Text(
              opt.label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              opt.desc,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                : null,
            onTap: () {
              HapticFeedback.selectionClick();
              settings.setTextSize(opt.size);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          final isSearching = _searchQuery.trim().isNotEmpty;
          final searchResults = isSearching ? _buildSearchResults(context, settings) : <Widget>[];

          return AnimationLimiter(
            child: CustomScrollView(
              slivers: [
                FrostedGlassSliverAppBar(
                  showBackButton: true,
                  title: Container(
                    height: 44,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: '${AppLocalizations.of(context)!.settingsTitle} / Search...',
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedSearchCategory = 'All';
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                if (isSearching)
                  SliverToBoxAdapter(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _searchCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = _searchCategories[index];
                          final isSelected = _selectedSearchCategory == cat;
                          return AppChip(
                            label: cat,
                            isSelected: isSelected,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedSearchCategory = cat;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),

                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      isSearching
                          ? (searchResults.isNotEmpty
                              ? searchResults
                              : [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 48),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.search_off_rounded,
                                          size: 56,
                                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No settings matching "$_searchQuery"',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Quick suggestions:',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          alignment: WrapAlignment.center,
                                          children: ['SMS', 'Theme', 'Lock', 'Backup', 'Currency', 'Tags'].map((term) {
                                            return ActionChip(
                                              label: Text(term),
                                              avatar: const Icon(Icons.search, size: 14),
                                              onPressed: () {
                                                HapticFeedback.selectionClick();
                                                _searchController.text = term;
                                                setState(() {
                                                  _searchQuery = term;
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ])
                          : AnimationConfiguration.toStaggeredList(
                              duration: const Duration(milliseconds: 220),
                              childAnimationBuilder: (widget) => SlideAnimation(
                                verticalOffset: 24.0,
                                child: FadeInAnimation(child: widget),
                              ),
                              children: [
                                // 0. Top Hero Dashboard Card
                                SettingsHeroCard(
                                  isAppLockEnabled: settings.appLockEnabled,
                                  isFinancialManagerEnabled: settings.showFinancialManager,
                                  isPeriodTrackerEnabled: settings.isPeriodTrackerEnabled,
                                  isAiEnabled: settings.useOnDeviceAi,
                                  autoBackupEnabled: settings.autoBackupEnabled,
                                  lastAutoBackupTimeFormatted: settings.lastAutoBackupTime != null
                                      ? _formatLastBackupTime(settings.lastAutoBackupTime!)
                                      : null,
                                  currentThemeMode: settings.themeMode,
                                  onThemeModeChanged: settings.setThemeMode,
                                ),

                                // 1. Manage Features Section
                                SettingsSection(
                                  title: 'Manage Features',
                                  icon: Icons.apps_outlined,
                                  children: [
                                    SettingsSwitchTile(
                                      icon: Icons.account_balance_wallet_outlined,
                                      iconColor: colorScheme.primary,
                                      iconBackgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                                      title: 'Financial Manager',
                                      subtitle: 'Enable expense tracking & SMS ledger',
                                      value: settings.showFinancialManager,
                                      onChanged: settings.setShowFinancialManager,
                                    ),
                                    const _Divider(),
                                    SettingsSwitchTile(
                                      icon: Icons.calendar_month_outlined,
                                      iconColor: colorScheme.secondary,
                                      iconBackgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                                      title: 'Period Tracker',
                                      subtitle: 'Optional cycle tracking & predictions',
                                      value: settings.isPeriodTrackerEnabled,
                                      onChanged: settings.setIsPeriodTrackerEnabled,
                                    ),
                                  ],
                                ),

                                // 2. Financial Manager Settings
                                if (settings.showFinancialManager)
                                  SettingsSection(
                                    title: 'Financial Manager Settings',
                                    icon: Icons.wallet_outlined,
                                    children: [
                                      SettingsTile(
                                        icon: Icons.currency_exchange_outlined,
                                        iconColor: colorScheme.primary,
                                        title: 'Currency',
                                        subtitle: 'Base ledger currency symbol',
                                        valueBadge: settings.currency,
                                        showArrow: true,
                                        onTap: () => _showCurrencyPicker(context, settings),
                                      ),
                                      const _Divider(),
                                      SettingsTile(
                                        icon: Icons.sms_outlined,
                                        iconColor: colorScheme.secondary,
                                        title: 'Advanced SMS Import',
                                        subtitle: 'Fetch past bank transactions from messages',
                                        showArrow: true,
                                        onTap: () => showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          showDragHandle: true,
                                          builder: (_) => const SmsImportSheet(),
                                        ),
                                      ),
                                      const _Divider(),
                                      SettingsTile(
                                        icon: Icons.category_outlined,
                                        iconColor: colorScheme.tertiary,
                                        title: 'Manage Categories',
                                        subtitle: 'Customise keywords and create new categories',
                                        showArrow: true,
                                        onTap: () => AppRoute.push(context, const CategoryManagementScreen()),
                                      ),
                                      const _Divider(),
                                      SettingsTile(
                                        icon: Icons.contacts_outlined,
                                        iconColor: colorScheme.primary,
                                        title: 'SMS Contacts',
                                        subtitle: 'Manage bank & custom senders for auto-import',
                                        showArrow: true,
                                        onTap: () => AppRoute.push(context, const SmsContactsScreen()),
                                      ),
                                      const _Divider(),
                                      SettingsTile(
                                        icon: Icons.event_repeat_outlined,
                                        iconColor: colorScheme.secondary,
                                        title: 'Recurring Transactions',
                                        subtitle: 'Manage automatically repeating entries',
                                        showArrow: true,
                                        onTap: () => showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          showDragHandle: true,
                                          builder: (_) => const RecurringRulesSheet(),
                                        ),
                                      ),
                                      const _Divider(),
                                      SettingsTile(
                                        icon: Icons.rule_folder_outlined,
                                        iconColor: colorScheme.tertiary,
                                        title: 'SMS Import Rules',
                                        subtitle: 'Manage auto-categorization and transaction rules',
                                        showArrow: true,
                                        onTap: () => AppRoute.push(context, const SmsRulesScreen()),
                                      ),
                                      const _Divider(),
                                      SettingsSwitchTile(
                                        icon: Icons.sync_outlined,
                                        iconColor: colorScheme.primary,
                                        title: 'SMS Auto-Sync',
                                        subtitle: 'Import bank transactions automatically in background',
                                        value: settings.dailySyncEnabled,
                                        onChanged: settings.setDailySyncEnabled,
                                      ),
                                      if (settings.dailySyncEnabled) ...[
                                        const _Divider(),
                                        SettingsTile(
                                          icon: Icons.access_time_outlined,
                                          iconColor: colorScheme.secondary,
                                          title: 'Auto-Sync Time',
                                          subtitle: 'Scheduled background execution time',
                                          valueBadge: _formatTimeOfDay(context, settings.dailySyncTime),
                                          showArrow: true,
                                          onTap: () => _showTimePicker(context, settings),
                                        ),
                                      ],
                                    ],
                                  ),

                                // 3. Period Tracker Settings
                                if (settings.isPeriodTrackerEnabled)
                                  SettingsSection(
                                    title: 'Period Tracker Settings',
                                    icon: Icons.calendar_today_outlined,
                                    children: [
                                      SettingsTile(
                                        icon: Icons.notifications_none_outlined,
                                        iconColor: colorScheme.secondary,
                                        title: 'Discreet Notification Text',
                                        subtitle: 'Text shown in cycle prediction alerts',
                                        valueBadge: settings.discreetNotificationText,
                                        showArrow: true,
                                        onTap: () => _showNotificationTextDialog(context, settings),
                                      ),
                                    ],
                                  ),

                                // 4. Privacy & Security
                                SettingsSection(
                                  title: 'Privacy & Security',
                                  icon: Icons.security_outlined,
                                  children: [
                                    SettingsSwitchTile(
                                      icon: Icons.lock_outline,
                                      iconColor: colorScheme.primary,
                                      title: 'App Lock',
                                      subtitle: 'Require authentication to open app',
                                      value: settings.appLockEnabled,
                                      onChanged: settings.setAppLockEnabled,
                                    ),
                                    if (settings.appLockEnabled) ...[
                                      const _Divider(),
                                      SettingsSwitchTile(
                                        icon: Icons.fingerprint_outlined,
                                        iconColor: colorScheme.secondary,
                                        title: 'Use Biometrics',
                                        subtitle: 'Require biometric scan specifically',
                                        value: settings.useBiometrics,
                                        onChanged: settings.setUseBiometrics,
                                      ),
                                      const _Divider(),
                                      SettingsTile(
                                        icon: Icons.timer_outlined,
                                        iconColor: colorScheme.tertiary,
                                        title: 'Auto-Lock Timeout',
                                        subtitle: 'Inactivity delay before locking',
                                        valueBadge: _getTimeoutLabel(settings.appLockTimeout),
                                        showArrow: true,
                                        onTap: () => _showTimeoutPicker(context, settings),
                                      ),
                                    ],
                                  ],
                                ),

                                // 5. Appearance & UI
                                SettingsSection(
                                  title: 'Appearance & UI',
                                  icon: Icons.palette_outlined,
                                  children: [
                                    SettingsSegmentedTile<ThemeMode>(
                                      icon: Icons.brightness_6_outlined,
                                      title: 'Theme Preference',
                                      subtitle: 'App visual color theme',
                                      segments: const [
                                        ButtonSegment(
                                          value: ThemeMode.system,
                                          icon: Icon(Icons.brightness_auto_rounded, size: 16),
                                          label: Text('System'),
                                        ),
                                        ButtonSegment(
                                          value: ThemeMode.light,
                                          icon: Icon(Icons.light_mode_rounded, size: 16),
                                          label: Text('Light'),
                                        ),
                                        ButtonSegment(
                                          value: ThemeMode.dark,
                                          icon: Icon(Icons.dark_mode_rounded, size: 16),
                                          label: Text('Dark'),
                                        ),
                                      ],
                                      selectedValue: settings.themeMode,
                                      onSelectionChanged: settings.setThemeMode,
                                    ),
                                    const _Divider(),
                                    SettingsSwitchTile(
                                      icon: Icons.color_lens_outlined,
                                      iconColor: colorScheme.secondary,
                                      title: 'Dynamic Wallpaper Theme',
                                      subtitle: 'Match app colors with device wallpaper (Android 12+)',
                                      value: settings.useDynamicColor,
                                      onChanged: settings.setUseDynamicColor,
                                    ),
                                    const _Divider(),
                                    SettingsSegmentedTile<double>(
                                      icon: Icons.text_fields,
                                      title: 'Text Scale',
                                      subtitle: 'Global font sizing',
                                      segments: const [
                                        ButtonSegment(value: 14.0, label: Text('Small')),
                                        ButtonSegment(value: 16.0, label: Text('Medium')),
                                        ButtonSegment(value: 20.0, label: Text('Large')),
                                      ],
                                      selectedValue: settings.textSize,
                                      onSelectionChanged: settings.setTextSize,
                                    ),
                                  ],
                                ),

                                // 6. Organization & Folders
                                SettingsSection(
                                  title: 'Organization & Folders',
                                  icon: Icons.folder_open_outlined,
                                  children: [
                                    SettingsTile(
                                      icon: Icons.label_outline,
                                      iconColor: colorScheme.primary,
                                      title: 'Manage Tags',
                                      subtitle: 'Rename or delete note tags',
                                      showArrow: true,
                                      onTap: () => AppRoute.push(context, const ManageTagsScreen()),
                                    ),
                                    const _Divider(),
                                    SettingsTile(
                                      icon: Icons.archive_outlined,
                                      iconColor: colorScheme.secondary,
                                      title: 'Archive',
                                      subtitle: 'View archived notes',
                                      showArrow: true,
                                      onTap: () => AppRoute.push(
                                        context,
                                        const FilteredNotesScreen(filterType: FilterType.archived),
                                      ),
                                    ),
                                    const _Divider(),
                                    SettingsTile(
                                      icon: Icons.delete_outline,
                                      iconColor: colorScheme.error,
                                      iconBackgroundColor: colorScheme.errorContainer.withValues(alpha: 0.4),
                                      title: 'Trash',
                                      subtitle: 'View deleted notes',
                                      showArrow: true,
                                      onTap: () => AppRoute.push(
                                        context,
                                        const FilteredNotesScreen(filterType: FilterType.trash),
                                      ),
                                    ),
                                    const _Divider(),
                                    SettingsTile(
                                      icon: Icons.auto_delete_outlined,
                                      iconColor: colorScheme.tertiary,
                                      title: 'Trash Auto-Purge',
                                      subtitle: 'Automatic deletion schedule for trash',
                                      valueBadge: settings.trashAutoPurgeDays <= 0
                                          ? 'Disabled'
                                          : '${settings.trashAutoPurgeDays} Days',
                                      showArrow: true,
                                      onTap: () => _showTrashPurgeDialog(context, settings),
                                    ),
                                  ],
                                ),

                                // 7. Local AI Features
                                SettingsSection(
                                  title: 'Local AI Features',
                                  icon: Icons.psychology_outlined,
                                  children: [
                                    if (settings.isDeviceAiSupported)
                                      SettingsSwitchTile(
                                        icon: Icons.auto_awesome_outlined,
                                        iconColor: colorScheme.primary,
                                        title: 'Gemini Nano AI',
                                        subtitle: 'Enable offline summaries, tag suggestions & smart SMS parsing',
                                        value: settings.useOnDeviceAi,
                                        onChanged: settings.setUseOnDeviceAi,
                                      )
                                    else
                                      Material(
                                        color: Colors.transparent,
                                        child: ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(9),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                              borderRadius: BorderRadius.circular(AppLayout.radiusM),
                                            ),
                                            child: Icon(
                                              Icons.auto_awesome_outlined,
                                              size: 20,
                                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                                            ),
                                          ),
                                          title: Text(
                                            'Gemini Nano Offline AI',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Unsupported on this device (requires compatible NPU and Android AI Core)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                                            ),
                                          ),
                                          trailing: Icon(
                                            Icons.info_outline,
                                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        ),
                                      ),
                                  ],
                                ),

                                // 8. Data & Backup
                                SettingsSection(
                                  title: 'Data & Backup',
                                  icon: Icons.cloud_sync_outlined,
                                  children: [
                                    SettingsTile(
                                      icon: Icons.devices_rounded,
                                      iconColor: colorScheme.tertiary,
                                      title: 'P2P Device Sync',
                                      subtitle: 'Sync notes between devices (Local / Relay)',
                                      showArrow: true,
                                      onTap: () => AppRoute.push(context, const P2pSyncScreen()),
                                    ),
                                    const _Divider(),
                                    SettingsTile(
                                      icon: Icons.download_outlined,
                                      iconColor: colorScheme.primary,
                                      title: 'Export Backup',
                                      subtitle: 'Save notes to an encrypted JSON file',
                                      showArrow: true,
                                      onTap: () => BackupService.exportBackup(context),
                                    ),
                                    const _Divider(),
                                    SettingsTile(
                                      icon: Icons.upload_outlined,
                                      iconColor: colorScheme.secondary,
                                      title: 'Import Backup',
                                      subtitle: 'Restore from a JSON backup file',
                                      showArrow: true,
                                      onTap: () => BackupService.importBackup(context),
                                    ),
                                    if (!kIsWeb && Platform.isAndroid) ...[
                                      const _Divider(),
                                      SettingsSwitchTile(
                                        icon: Icons.backup_outlined,
                                        iconColor: colorScheme.tertiary,
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
                                        SettingsTile(
                                          icon: Icons.schedule_outlined,
                                          iconColor: colorScheme.primary,
                                          title: 'Backup Frequency',
                                          subtitle: 'Frequency of automated backup tasks',
                                          valueBadge: _getFrequencyLabel(settings.autoBackupFrequency),
                                          showArrow: true,
                                          onTap: () => _showFrequencyPicker(context, settings),
                                        ),
                                        const _Divider(),
                                        SettingsTile(
                                          icon: Icons.folder_outlined,
                                          iconColor: colorScheme.secondary,
                                          title: 'Backup Location',
                                          subtitle: settings.autoBackupPath ?? 'App default directory',
                                          showArrow: true,
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
                                          SettingsTile(
                                            icon: Icons.history_outlined,
                                            iconColor: colorScheme.tertiary,
                                            title: 'Last Auto Backup',
                                            subtitle: 'Most recent successful backup',
                                            valueBadge: _formatLastBackupTime(settings.lastAutoBackupTime!),
                                          ),
                                        ],
                                      ],
                                    ],
                                  ],
                                ),

                                // 9. About Section
                                SettingsSection(
                                  title: 'About',
                                  icon: Icons.info_outline_rounded,
                                  children: [
                                    SettingsTile(
                                      icon: Icons.star_outline_rounded,
                                      iconColor: Colors.amber.shade700,
                                      iconBackgroundColor: Colors.amber.withValues(alpha: 0.2),
                                      title: 'Rate & Feedback',
                                      subtitle: 'Love the app? Rate us on the Play Store',
                                      trailing: Icon(
                                        Icons.open_in_new_rounded,
                                        size: 18,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      onTap: () => _launchUrl(
                                        'https://play.google.com/store/apps/details?id=com.saadhjawwadh.notebook',
                                      ),
                                    ),
                                    const _Divider(),
                                    SettingsTile(
                                      icon: Icons.history_rounded,
                                      iconColor: colorScheme.primary,
                                      title: 'Changelog',
                                      subtitle: 'View version release logs',
                                      showArrow: true,
                                      onTap: () => AppRoute.push(context, const ChangelogScreen()),
                                    ),
                                    const _Divider(),
                                    SettingsTile(
                                      icon: Icons.rocket_launch_outlined,
                                      iconColor: colorScheme.secondary,
                                      title: 'Replay Setup & Intro',
                                      subtitle: 'Configure theme, modules, and AI assistant',
                                      showArrow: true,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const OnboardingScreen(isReplay: true),
                                          ),
                                        );
                                      },
                                    ),
                                    const _Divider(),
                                    FutureBuilder<PackageInfo>(
                                      future: PackageInfo.fromPlatform(),
                                      builder: (context, snapshot) {
                                        final version = snapshot.hasData
                                            ? 'v${snapshot.data!.version}+${snapshot.data!.buildNumber}'
                                            : 'Loading...';
                                        return SettingsTile(
                                          icon: Icons.info_outline_rounded,
                                          iconColor: colorScheme.tertiary,
                                          title: 'Version',
                                          subtitle: version,
                                          showArrow: true,
                                          onTap: () => _launchUrl(AppConstants.releaseUrl),
                                        );
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

  List<Widget> _buildSearchResults(BuildContext context, SettingsProvider settings) {
    final query = _searchQuery.toLowerCase().trim();
    final catFilter = _selectedSearchCategory;

    final items = <Widget>[];

    bool matchesCategory(String categoryName) {
      if (catFilter == 'All') return true;
      return categoryName.toLowerCase() == catFilter.toLowerCase();
    }

    bool matchesQuery(String title, [String? subtitle]) {
      return title.toLowerCase().contains(query) ||
          (subtitle != null && subtitle.toLowerCase().contains(query));
    }

    void addTile(Widget tile, String categoryName, String title, [String? subtitle]) {
      if (matchesCategory(categoryName) && matchesQuery(title, subtitle)) {
        if (items.isNotEmpty) items.add(const _Divider());
        items.add(tile);
      }
    }

    // 1. Manage Features
    addTile(
      SettingsSwitchTile(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Financial Manager',
        subtitle: 'Enable expense tracking',
        value: settings.showFinancialManager,
        onChanged: settings.setShowFinancialManager,
      ),
      'Finances',
      'Financial Manager',
      'Enable expense tracking',
    );
    addTile(
      SettingsSwitchTile(
        icon: Icons.calendar_month_outlined,
        title: 'Period Tracker',
        subtitle: 'Optional cycle tracking',
        value: settings.isPeriodTrackerEnabled,
        onChanged: settings.setIsPeriodTrackerEnabled,
      ),
      'Finances',
      'Period Tracker',
      'Optional cycle tracking',
    );

    // 2. Financial Manager Settings
    if (settings.showFinancialManager) {
      addTile(
        SettingsTile(
          icon: Icons.currency_exchange_outlined,
          title: 'Currency',
          subtitle: settings.currency,
          valueBadge: settings.currency,
          showArrow: true,
          onTap: () => _showCurrencyPicker(context, settings),
        ),
        'Finances',
        'Currency',
        settings.currency,
      );
      addTile(
        SettingsTile(
          icon: Icons.sms_outlined,
          title: 'Advanced SMS Import',
          subtitle: 'Fetch past bank transactions from messages',
          showArrow: true,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => const SmsImportSheet(),
          ),
        ),
        'Finances',
        'Advanced SMS Import',
        'Fetch past bank transactions from messages',
      );
      addTile(
        SettingsTile(
          icon: Icons.category_outlined,
          title: 'Manage Categories',
          subtitle: 'Customise keywords and create new categories',
          showArrow: true,
          onTap: () => AppRoute.push(context, const CategoryManagementScreen()),
        ),
        'Finances',
        'Manage Categories',
        'Customise keywords and create new categories',
      );
      addTile(
        SettingsTile(
          icon: Icons.contacts_outlined,
          title: 'SMS Contacts',
          subtitle: 'Manage bank & custom senders for auto-import',
          showArrow: true,
          onTap: () => AppRoute.push(context, const SmsContactsScreen()),
        ),
        'Finances',
        'SMS Contacts',
        'Manage bank & custom senders for auto-import',
      );
      addTile(
        SettingsTile(
          icon: Icons.event_repeat_outlined,
          title: 'Recurring Transactions',
          subtitle: 'Manage automatically repeating entries',
          showArrow: true,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => const RecurringRulesSheet(),
          ),
        ),
        'Finances',
        'Recurring Transactions',
        'Manage automatically repeating entries',
      );
      addTile(
        SettingsTile(
          icon: Icons.rule_folder_outlined,
          title: 'SMS Import Rules',
          subtitle: 'Manage auto-categorization and transaction type rules',
          showArrow: true,
          onTap: () => AppRoute.push(context, const SmsRulesScreen()),
        ),
        'Finances',
        'SMS Import Rules',
        'Manage auto-categorization and transaction type rules',
      );
      addTile(
        SettingsTile(
          icon: Icons.file_upload_outlined,
          title: 'Import Transactions (CSV)',
          subtitle: 'Import ledger records from a CSV file',
          showArrow: true,
          onTap: () => BackupService.importTransactionsFromCsv(context),
        ),
        'Finances',
        'Import Transactions (CSV)',
        'Import ledger records from a CSV file',
      );
      addTile(
        SettingsSwitchTile(
          icon: Icons.sync_outlined,
          title: 'SMS Auto-Sync',
          subtitle: 'Import bank transactions automatically in background',
          value: settings.dailySyncEnabled,
          onChanged: settings.setDailySyncEnabled,
        ),
        'Finances',
        'SMS Auto-Sync',
        'Import bank transactions automatically in background',
      );
      if (settings.dailySyncEnabled) {
        final timeSub = _formatTimeOfDay(context, settings.dailySyncTime);
        addTile(
          SettingsTile(
            icon: Icons.access_time_outlined,
            title: 'Auto-Sync Time',
            subtitle: timeSub,
            valueBadge: timeSub,
            showArrow: true,
            onTap: () => _showTimePicker(context, settings),
          ),
          'Finances',
          'Auto-Sync Time',
          timeSub,
        );
        addTile(
          SettingsTile(
            icon: Icons.sync,
            title: 'Test Auto-Sync Now',
            subtitle: 'Run background SMS sync test now to verify functionality',
            onTap: () async {
              await HapticFeedback.mediumImpact();
              if (!context.mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(const SnackBar(content: Text('Running SMS sync test...')));
              final success = await SmsService.performDailyTransactionSync();
              messenger.showSnackBar(SnackBar(
                content: Text(success ? 'SMS sync test completed successfully.' : 'SMS sync test completed.'),
              ));
            },
          ),
          'Finances',
          'Test Auto-Sync Now',
          'Run background SMS sync test now',
        );
      }
    }

    // 3. Period Tracker Settings
    if (settings.isPeriodTrackerEnabled) {
      addTile(
        SettingsTile(
          icon: Icons.notifications_none_outlined,
          title: 'Discreet Notification Text',
          subtitle: settings.discreetNotificationText,
          valueBadge: settings.discreetNotificationText,
          showArrow: true,
          onTap: () => _showNotificationTextDialog(context, settings),
        ),
        'Finances',
        'Discreet Notification Text',
        settings.discreetNotificationText,
      );
    }

    // 4. Privacy & Security
    addTile(
      SettingsSwitchTile(
        icon: Icons.lock_outline,
        title: 'App Lock',
        subtitle: 'Require authentication to open app',
        value: settings.appLockEnabled,
        onChanged: settings.setAppLockEnabled,
      ),
      'Security',
      'App Lock',
      'Require authentication to open app',
    );
    if (settings.appLockEnabled) {
      addTile(
        SettingsSwitchTile(
          icon: Icons.fingerprint_outlined,
          title: 'Use Biometrics',
          subtitle: 'Require biometric scan specifically',
          value: settings.useBiometrics,
          onChanged: settings.setUseBiometrics,
        ),
        'Security',
        'Use Biometrics',
        'Require biometric scan specifically',
      );
      addTile(
        SettingsTile(
          icon: Icons.timer_outlined,
          title: 'Auto-Lock Timeout',
          subtitle: _getTimeoutLabel(settings.appLockTimeout),
          valueBadge: _getTimeoutLabel(settings.appLockTimeout),
          showArrow: true,
          onTap: () => _showTimeoutPicker(context, settings),
        ),
        'Security',
        'Auto-Lock Timeout',
        _getTimeoutLabel(settings.appLockTimeout),
      );
    }

    // 5. Appearance & UI
    addTile(
      SettingsTile(
        icon: Icons.palette_outlined,
        title: 'Theme',
        subtitle: _getThemeLabel(settings.themeMode),
        valueBadge: _getThemeLabel(settings.themeMode),
        showArrow: true,
        onTap: () => _showThemePicker(context, settings),
      ),
      'Appearance',
      'Theme',
      _getThemeLabel(settings.themeMode),
    );
    addTile(
      SettingsSwitchTile(
        icon: Icons.color_lens_outlined,
        title: 'Dynamic Wallpaper Theme',
        subtitle: 'Match app colors with device wallpaper (Android 12+)',
        value: settings.useDynamicColor,
        onChanged: settings.setUseDynamicColor,
      ),
      'Appearance',
      'Dynamic Wallpaper Theme',
      'Match app colors with device wallpaper (Android 12+)',
    );
    addTile(
      SettingsTile(
        icon: Icons.text_fields,
        title: 'Text Size',
        subtitle: settings.textSizeLabel,
        valueBadge: settings.textSizeLabel,
        showArrow: true,
        onTap: () => _showTextSizePicker(context, settings),
      ),
      'Appearance',
      'Text Size',
      settings.textSizeLabel,
    );

    // 6. Organization & Folders
    addTile(
      SettingsTile(
        icon: Icons.label_outline,
        title: 'Manage Tags',
        subtitle: 'Rename or delete tags',
        showArrow: true,
        onTap: () => AppRoute.push(context, const ManageTagsScreen()),
      ),
      'Notes & Tags',
      'Manage Tags',
      'Rename or delete tags',
    );
    addTile(
      SettingsTile(
        icon: Icons.archive_outlined,
        title: 'Archive',
        subtitle: 'View archived notes',
        showArrow: true,
        onTap: () => AppRoute.push(
          context,
          const FilteredNotesScreen(filterType: FilterType.archived),
        ),
      ),
      'Notes & Tags',
      'Archive',
      'View archived notes',
    );
    addTile(
      SettingsTile(
        icon: Icons.delete_outline,
        title: 'Trash',
        subtitle: 'View deleted notes',
        showArrow: true,
        onTap: () => AppRoute.push(
          context,
          const FilteredNotesScreen(filterType: FilterType.trash),
        ),
      ),
      'Notes & Tags',
      'Trash',
      'View deleted notes',
    );
    addTile(
      SettingsTile(
        icon: Icons.auto_delete_outlined,
        title: 'Trash Auto-Purge',
        subtitle: settings.trashAutoPurgeDays <= 0
            ? 'Disabled'
            : 'Auto-delete after ${settings.trashAutoPurgeDays} days',
        valueBadge: settings.trashAutoPurgeDays <= 0
            ? 'Disabled'
            : '${settings.trashAutoPurgeDays} Days',
        showArrow: true,
        onTap: () => _showTrashPurgeDialog(context, settings),
      ),
      'Notes & Tags',
      'Trash Auto-Purge',
      'Automatic deletion schedule for trash',
    );

    // 7. Local AI
    if (settings.isDeviceAiSupported) {
      addTile(
        SettingsSwitchTile(
          icon: Icons.auto_awesome_outlined,
          title: 'Gemini Nano AI',
          subtitle: 'Enable offline summaries, tag suggestions & smart SMS parsing',
          value: settings.useOnDeviceAi,
          onChanged: settings.setUseOnDeviceAi,
        ),
        'Data & Backup',
        'Gemini Nano AI',
        'Enable offline summaries, tag suggestions & smart SMS parsing',
      );
    }

    // 8. Data & Backup
    addTile(
      SettingsTile(
        icon: Icons.download_outlined,
        title: 'Export Backup',
        subtitle: 'Save notes to a JSON file',
        showArrow: true,
        onTap: () => BackupService.exportBackup(context),
      ),
      'Data & Backup',
      'Export Backup',
      'Save notes to a JSON file',
    );
    addTile(
      SettingsTile(
        icon: Icons.upload_outlined,
        title: 'Import Backup',
        subtitle: 'Restore from a JSON file',
        showArrow: true,
        onTap: () => BackupService.importBackup(context),
      ),
      'Data & Backup',
      'Import Backup',
      'Restore from a JSON file',
    );
    if (!kIsWeb && Platform.isAndroid) {
      addTile(
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
        'Data & Backup',
        'Auto Backup',
        'Schedule automatic backups',
      );
      if (settings.autoBackupEnabled) {
        addTile(
          SettingsTile(
            icon: Icons.schedule_outlined,
            title: 'Backup Frequency',
            subtitle: _getFrequencyLabel(settings.autoBackupFrequency),
            valueBadge: _getFrequencyLabel(settings.autoBackupFrequency),
            showArrow: true,
            onTap: () => _showFrequencyPicker(context, settings),
          ),
          'Data & Backup',
          'Backup Frequency',
          _getFrequencyLabel(settings.autoBackupFrequency),
        );
        addTile(
          SettingsTile(
            icon: Icons.folder_outlined,
            title: 'Backup Location',
            subtitle: settings.autoBackupPath ?? 'App default directory',
            showArrow: true,
            onTap: () async {
              AppLockScreen.ignoreNextResumeLock();
              final dir = await FilePicker.platform.getDirectoryPath();
              if (dir != null) {
                await settings.setAutoBackupPath(dir);
                await syncAutoBackupSchedule();
              }
            },
          ),
          'Data & Backup',
          'Backup Location',
          settings.autoBackupPath ?? 'App default directory',
        );
      }
    }

    // 9. About
    addTile(
      SettingsTile(
        icon: Icons.star_outline_rounded,
        title: 'Rate & Feedback',
        subtitle: 'Love the app? Rate us on the Play Store',
        trailing: Icon(
          Icons.open_in_new_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: () => _launchUrl('https://play.google.com/store/apps/details?id=com.saadhjawwadh.notebook'),
      ),
      'Notes & Tags',
      'Rate & Feedback',
      'Love the app? Rate us on the Play Store',
    );
    addTile(
      SettingsTile(
        icon: Icons.history_rounded,
        title: 'Changelog',
        subtitle: 'View version release logs',
        showArrow: true,
        onTap: () => AppRoute.push(context, const ChangelogScreen()),
      ),
      'Notes & Tags',
      'Changelog',
      'View version release logs',
    );
    addTile(
      SettingsTile(
        icon: Icons.rocket_launch_outlined,
        title: 'Replay Setup & Intro',
        subtitle: 'Configure theme, modules, and AI assistant',
        showArrow: true,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const OnboardingScreen(isReplay: true),
            ),
          );
        },
      ),
      'Notes & Tags',
      'Replay Setup & Intro',
      'Configure theme, modules, and AI assistant',
    );

    if (items.isEmpty) return [];

    final matchingCount = (items.length / 2).ceil();

    return [
      SettingsSection(
        title: 'Matching Results ($matchingCount)',
        icon: Icons.search_rounded,
        children: items,
      ),
    ];
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

  void _showCurrencyPicker(BuildContext context, SettingsProvider settings) {
    AppBottomSheet.show(
      context: context,
      title: 'Select Currency',
      child: Container(
        constraints: const BoxConstraints(maxHeight: 380),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: AppConstants.currencies.length,
          itemBuilder: (context, index) {
            final currency = AppConstants.currencies[index];
            final isSelected = settings.currency == currency;
            final colorScheme = Theme.of(context).colorScheme;

            return ListTile(
              leading: Icon(
                Icons.monetization_on_outlined,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              title: Text(
                currency,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                  : null,
              onTap: () {
                HapticFeedback.selectionClick();
                settings.setCurrency(currency);
                WidgetHelper.updateWidgetData();
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  void _showNotificationTextDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.discreetNotificationText);

    AppBottomSheet.show(
      context: context,
      title: 'Discreet Notification Text',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize the discreet notification message for upcoming period predictions.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g., Check the app',
              labelText: 'Alert Text',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppLayout.radiusM),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  if (controller.text.trim().isNotEmpty) {
                    settings.setDiscreetNotificationText(controller.text.trim());
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return 'Daily';
    }
  }

  String _formatLastBackupTime(String isoTime) {
    final dt = DateTime.tryParse(isoTime);
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  void _showFrequencyPicker(BuildContext context, SettingsProvider settings) {
    final options = [
      (label: 'Daily', value: 'daily', desc: 'Automatic backup generated every 24 hours'),
      (label: 'Weekly', value: 'weekly', desc: 'Automatic backup generated once per week'),
      (label: 'Monthly', value: 'monthly', desc: 'Automatic backup generated once per month'),
    ];

    AppBottomSheet.show(
      context: context,
      title: 'Backup Frequency',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = settings.autoBackupFrequency == opt.value;
          final colorScheme = Theme.of(context).colorScheme;

          return ListTile(
            leading: Icon(
              Icons.schedule_outlined,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            title: Text(
              opt.label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              opt.desc,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                : null,
            onTap: () async {
              await HapticFeedback.selectionClick();
              await settings.setAutoBackupFrequency(opt.value);
              await syncAutoBackupSchedule();
              if (context.mounted) Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    AppLockScreen.ignoreNextResumeLock();
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  String _getTimeoutLabel(int seconds) {
    if (seconds == 0) return 'Immediately';
    if (seconds < 60) return '$seconds seconds';
    return '${seconds ~/ 60} minute${seconds >= 120 ? "s" : ""}';
  }

  void _showTimeoutPicker(BuildContext context, SettingsProvider settings) {
    final options = [
      (label: 'Immediately', value: 0, desc: 'Lock as soon as app leaves foreground'),
      (label: '10 seconds', value: 10, desc: 'Lock after 10s of background inactivity'),
      (label: '30 seconds', value: 30, desc: 'Lock after 30s of background inactivity'),
      (label: '1 minute', value: 60, desc: 'Lock after 1m of background inactivity'),
      (label: '5 minutes', value: 300, desc: 'Lock after 5m of background inactivity'),
    ];

    AppBottomSheet.show(
      context: context,
      title: 'Auto-Lock Timeout',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = settings.appLockTimeout == opt.value;
          final colorScheme = Theme.of(context).colorScheme;

          return ListTile(
            leading: Icon(
              Icons.timer_outlined,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            title: Text(
              opt.label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              opt.desc,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                : null,
            onTap: () {
              HapticFeedback.selectionClick();
              settings.setAppLockTimeout(opt.value);
              Navigator.pop(context);
            },
          );
        }).toList(),
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
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await settings.setDailySyncTime(formattedTime);
    }
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
