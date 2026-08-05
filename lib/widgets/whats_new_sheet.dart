import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';
import '../core/theme/app_layout.dart';
import '../core/ui/app_card.dart';
import '../widgets/bouncing_widget.dart';
import '../features/sync/presentation/screens/p2p_sync_screen.dart';

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

    final categories = [
      _WhatsNewCategory(
        categoryTitle: "🌟 What's New",
        categoryColor: theme.colorScheme.primary,
        bgColor: theme.colorScheme.primaryContainer.withValues(alpha: isDark ? 0.3 : 0.4),
        items: [
          _WhatsNewItem(
            icon: Icons.sync_rounded,
            title: "Bi-Directional P2P Wi-Fi Sync",
            desc: "Merge notes, financial ledgers, and settings between devices over Wi-Fi without losing local edits.",
            actionLabel: "Try P2P Sync ➔",
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const P2pSyncScreen()),
              );
            },
          ),
          _WhatsNewItem(
            icon: Icons.sync_lock_rounded,
            title: "Reliable SMS Auto-Sync Engine",
            desc: "Background bank transaction sync now runs reliably with 48-hour catch-up sync, live status badges, and 1-tap test scanning.",
          ),
        ],
      ),
      _WhatsNewCategory(
        categoryTitle: "🚀 Improvements",
        categoryColor: theme.colorScheme.tertiary,
        bgColor: theme.colorScheme.tertiaryContainer.withValues(alpha: isDark ? 0.3 : 0.4),
        items: [
          _WhatsNewItem(
            icon: Icons.keyboard_rounded,
            title: "Ultra-Smooth Text Selection",
            desc: "Optimized keyboard D-Pad arrow key navigation and text selection in the editor for instant, stutter-free typing.",
          ),
          _WhatsNewItem(
            icon: Icons.palette_rounded,
            title: "Dynamic Light & Dark Hero Cards",
            desc: "Hero cards dynamically adjust pastel opacities in Light Mode and deep translucent fills in Dark Mode for crisp contrast.",
          ),
        ],
      ),
      _WhatsNewCategory(
        categoryTitle: "🐛 Fixes",
        categoryColor: theme.colorScheme.secondary,
        bgColor: theme.colorScheme.secondaryContainer.withValues(alpha: isDark ? 0.3 : 0.4),
        items: [
          _WhatsNewItem(
            icon: Icons.check_circle_outline_rounded,
            title: "RenderEditor Caret Calculation",
            desc: "Resolved issue where Quill editor container wrappers obscured cursor position calculations.",
          ),
        ],
      ),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppLayout.radiusXXL)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppLayout.radiusXXL)),
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
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppLayout.spaceXL),

                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppLayout.spaceM),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.stars_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 30,
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
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppLayout.radiusS),
                              ),
                              child: Text(
                                "Version $currentVersion",
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppLayout.spaceXL),

                  // Categorized Updates List
                  Expanded(
                    child: AnimationLimiter(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: categories.length,
                        itemBuilder: (context, catIndex) {
                          final category = categories[catIndex];
                          return AnimationConfiguration.staggeredList(
                            position: catIndex,
                            duration: const Duration(milliseconds: 280),
                            child: SlideAnimation(
                              verticalOffset: 24.0,
                              child: FadeInAnimation(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: AppLayout.spaceL),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Category Pill Tag
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppLayout.spaceM,
                                          vertical: AppLayout.spaceXS,
                                        ),
                                        decoration: BoxDecoration(
                                          color: category.bgColor,
                                          borderRadius: BorderRadius.circular(AppLayout.radiusS),
                                        ),
                                        child: Text(
                                          category.categoryTitle,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: category.categoryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppLayout.spaceM),

                                      // Items inside AppCard containers
                                      ...category.items.map((item) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: AppLayout.spaceS),
                                          child: AppCard(
                                            padding: const EdgeInsets.all(AppLayout.spaceM),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(AppLayout.spaceS),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(AppLayout.radiusM),
                                                  ),
                                                  child: Icon(
                                                    item.icon,
                                                    color: theme.colorScheme.primary,
                                                    size: 22,
                                                  ),
                                                ),
                                                const SizedBox(width: AppLayout.spaceM),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        item.title,
                                                        style: theme.textTheme.titleMedium?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        item.desc,
                                                        style: theme.textTheme.bodyMedium?.copyWith(
                                                          color: theme.colorScheme.onSurfaceVariant,
                                                          height: 1.35,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      if (item.actionLabel != null && item.onAction != null) ...[
                                                        const SizedBox(height: AppLayout.spaceS),
                                                        Align(
                                                          alignment: Alignment.centerLeft,
                                                          child: TextButton(
                                                            onPressed: () {
                                                              _finishWhatsNew(context);
                                                              item.onAction!();
                                                            },
                                                            style: TextButton.styleFrom(
                                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                              minimumSize: Size.zero,
                                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                              backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                                              foregroundColor: theme.colorScheme.primary,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(AppLayout.radiusS),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              item.actionLabel!,
                                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Got It Button
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
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "Awesome, Got It!",
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
        ),
      ),
    );
  }
}

class _WhatsNewCategory {
  final String categoryTitle;
  final Color categoryColor;
  final Color bgColor;
  final List<_WhatsNewItem> items;

  _WhatsNewCategory({
    required this.categoryTitle,
    required this.categoryColor,
    required this.bgColor,
    required this.items,
  });
}

class _WhatsNewItem {
  final IconData icon;
  final String title;
  final String desc;
  final String? actionLabel;
  final VoidCallback? onAction;

  _WhatsNewItem({
    required this.icon,
    required this.title,
    required this.desc,
    this.actionLabel,
    this.onAction,
  });
}
