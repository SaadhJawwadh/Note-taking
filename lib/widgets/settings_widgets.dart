import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_layout.dart';
import '../core/ui/app_chip.dart';
import 'bouncing_widget.dart';

/// Top Hero Dashboard Card displaying status indicators, active modules, and quick theme toggle.
class SettingsHeroCard extends StatelessWidget {
  final bool isAppLockEnabled;
  final bool isFinancialManagerEnabled;
  final bool isPeriodTrackerEnabled;
  final bool isAiEnabled;
  final bool autoBackupEnabled;
  final String? lastAutoBackupTimeFormatted;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const SettingsHeroCard({
    super.key,
    required this.isAppLockEnabled,
    required this.isFinancialManagerEnabled,
    required this.isPeriodTrackerEnabled,
    required this.isAiEnabled,
    required this.autoBackupEnabled,
    this.lastAutoBackupTimeFormatted,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusXXL),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        child: Container(
          padding: const EdgeInsets.all(AppLayout.spaceL),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceContainerHigh,
                colorScheme.primaryContainer.withValues(alpha: 0.15),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header & Security Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.settings_suggest_rounded,
                            size: 22,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: AppLayout.spaceM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Control Center',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Preferences & System Health',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppLayout.spaceS),
                  AppChip(
                    isCompact: true,
                    icon: isAppLockEnabled
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    label: isAppLockEnabled ? 'Protected' : 'Unlocked',
                    isSelected: isAppLockEnabled,
                    selectedBackgroundColor:
                        colorScheme.primaryContainer.withValues(alpha: 0.8),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    textColor: isAppLockEnabled
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ],
              ),

              const SizedBox(height: AppLayout.spaceL),
              const Divider(height: 1),
              const SizedBox(height: AppLayout.spaceM),

              // 2. Active Feature Module Badges
              Text(
                'ACTIVE MODULES & SYSTEM STATUS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: colorScheme.primary.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: AppLayout.spaceS),
              Wrap(
                spacing: AppLayout.spaceXS,
                runSpacing: AppLayout.spaceXS,
                children: [
                  if (isFinancialManagerEnabled)
                    AppChip(
                      isCompact: true,
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finances',
                      isSelected: true,
                      selectedBackgroundColor:
                          colorScheme.secondaryContainer.withValues(alpha: 0.7),
                      textColor: colorScheme.onSecondaryContainer,
                    ),
                  if (isPeriodTrackerEnabled)
                    AppChip(
                      isCompact: true,
                      icon: Icons.favorite_outline,
                      label: 'Health Tracker',
                      isSelected: true,
                      selectedBackgroundColor:
                          colorScheme.tertiaryContainer.withValues(alpha: 0.7),
                      textColor: colorScheme.onTertiaryContainer,
                    ),
                  if (isAiEnabled)
                    AppChip(
                      isCompact: true,
                      icon: Icons.auto_awesome_outlined,
                      label: 'Gemini AI',
                      isSelected: true,
                      selectedBackgroundColor:
                          colorScheme.primaryContainer.withValues(alpha: 0.7),
                      textColor: colorScheme.onPrimaryContainer,
                    ),
                  AppChip(
                    isCompact: true,
                    icon: autoBackupEnabled
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    label: autoBackupEnabled
                        ? (lastAutoBackupTimeFormatted != null
                            ? 'Backup: $lastAutoBackupTimeFormatted'
                            : 'Auto-Backup On')
                        : 'Manual Backup',
                    isSelected: autoBackupEnabled,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    textColor: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),

              const SizedBox(height: AppLayout.spaceL),

              // 3. Quick Theme Toggle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Theme Mode',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppLayout.spaceS),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded, size: 16),
                          label: Text('Auto'),
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
                      selected: {currentThemeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        HapticFeedback.selectionClick();
                        onThemeModeChanged(newSelection.first);
                      },
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppLayout.radiusXL),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            child: Column(
              children: [
                const SizedBox(height: 4),
                ...children,
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget? customLeading;
  final String title;
  final String? subtitle;
  final String? valueBadge;
  final Widget? trailing;
  final bool showArrow;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.customLeading,
    required this.title,
    this.subtitle,
    this.valueBadge,
    this.trailing,
    this.showArrow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveIconBg = iconBackgroundColor ??
        colorScheme.primaryContainer.withValues(alpha: 0.4);
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    final tileChild = Material(
      type: MaterialType.transparency,
      child: ListTile(
        leading: customLeading ??
            (icon != null
                ? Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: effectiveIconBg,
                      borderRadius: BorderRadius.circular(AppLayout.radiusM),
                    ),
                    child: Icon(icon, size: 20, color: effectiveIconColor),
                  )
                : null),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: trailing ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (valueBadge != null) ...[
                  AppChip(
                    isCompact: true,
                    label: valueBadge!,
                    backgroundColor:
                        colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                    textColor: colorScheme.onSurfaceVariant,
                  ),
                  if (showArrow) const SizedBox(width: AppLayout.spaceXS),
                ],
                if (showArrow)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colorScheme.outline,
                  ),
              ],
            ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
      ),
    );

    if (onTap != null) {
      return BouncingWidget(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: tileChild,
      );
    }

    return tileChild;
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveIconBg = iconBackgroundColor ??
        (value
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5));
    final effectiveIconColor = iconColor ??
        (value ? colorScheme.primary : colorScheme.onSurfaceVariant);

    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: effectiveIconBg,
            borderRadius: BorderRadius.circular(AppLayout.radiusM),
          ),
          child: Icon(icon, size: 20, color: effectiveIconColor),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        value: value,
        onChanged: (v) {
          HapticFeedback.selectionClick();
          onChanged(v);
        },
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        activeThumbColor: colorScheme.primary,
      ),
    );
  }
}

class SettingsSegmentedTile<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<ButtonSegment<T>> segments;
  final T selectedValue;
  final ValueChanged<T> onSelectionChanged;

  const SettingsSegmentedTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.segments,
    required this.selectedValue,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppLayout.radiusM),
                ),
                child: Icon(icon, size: 20, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              segments: segments,
              selected: {selectedValue},
              onSelectionChanged: (Set<T> newSelection) {
                HapticFeedback.selectionClick();
                onSelectionChanged(newSelection.first);
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
