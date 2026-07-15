import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';
import '../theme/app_layout.dart';
import '../widgets/bouncing_widget.dart';

class WhatsNewSheet extends StatelessWidget {
  final String currentVersion;

  const WhatsNewSheet({
    super.key,
    required this.currentVersion,
  });

  void _finishWhatsNew(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    await HapticFeedback.mediumImpact();
    await settings.setLastSeenVersion(currentVersion);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppLayout.radiusMAX)),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.3),
          width: 1.0,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppLayout.spaceM),
              // Top Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppLayout.spaceXL),
              
              // Title Block
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppLayout.spaceS),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppLayout.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What's New",
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          "Version $currentVersion",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppLayout.spaceXL),
              
              // Updates list
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFeatureItem(
                      theme,
                      icon: Icons.folder_open_outlined,
                      title: "Folder Selector Card",
                      desc: "Replaced the cluttered home screen greeting with an interactive folder card. Swap or create new folders inline and view active folder counts.",
                    ),
                    _buildFeatureItem(
                      theme,
                      icon: Icons.add_circle_outline_rounded,
                      title: "Accessible Note Creation",
                      desc: "Tapping the + FAB now shows a clean sheet to quickly write a Blank Note or choose a layout Template (Journal/Meeting/Shopping).",
                    ),
                    _buildFeatureItem(
                      theme,
                      icon: Icons.tablet_android_outlined,
                      title: "Responsive Tablet Layout",
                      desc: "Wide screens (>= 600dp) now display a sleek side Navigation Rail and double-column ledger analytics for a desktop-class experience.",
                    ),
                    _buildFeatureItem(
                      theme,
                      icon: Icons.table_view_rounded,
                      title: "CSV Ledger Export",
                      desc: "Export your transaction logs as standard RFC 4180 CSV files directly from the ledger app bar to analyze in Excel/Sheets/Python.",
                    ),
                    _buildFeatureItem(
                      theme,
                      icon: Icons.bolt_outlined,
                      title: "UX Polish & Snappy Alerts",
                      desc: "Swipe-to-trash/archive alerts and delete confirmations now dismiss in a snappy 3 seconds and clear other active bars instantly.",
                    ),
                  ],
                ),
              ),
              
              // Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppLayout.spaceL),
                child: BouncingWidget(
                  onTap: () => _finishWhatsNew(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: AppLayout.spaceM),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppLayout.radiusL),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "Awesome, Got It",
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String desc,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: AppLayout.spaceM),
      padding: const EdgeInsets.all(AppLayout.spaceM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppLayout.radiusL),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: AppLayout.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppLayout.spaceXS),
                Text(
                  desc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
