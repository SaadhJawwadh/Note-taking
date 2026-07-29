import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_layout.dart';

/// A unified, highly reusable frosted glass top app bar used across all screens.
/// Guarantees 100% visual symmetry, edge-to-edge blur, and standardized spacing.
class FrostedGlassSliverAppBar extends StatelessWidget {
  final Widget? title;
  final String? titleText;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final double height;

  const FrostedGlassSliverAppBar({
    super.key,
    this.title,
    this.titleText,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    this.height = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final totalHeight = statusBarHeight + height + 12.0;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && showBackButton) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: onBackPressed ??
            () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
      );
    }

    Widget headerContent;
    if (title != null) {
      headerContent = title!;
    } else {
      headerContent = Text(
        titleText ?? '',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
        overflow: TextOverflow.ellipsis,
      );
    }

    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      primary: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: totalHeight,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.only(
              top: statusBarHeight + 6,
              left: AppLayout.spaceL,
              right: AppLayout.spaceL,
              bottom: 6,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerLow
                  .withValues(alpha: isDark ? 0.82 : 0.80),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: isDark ? 0.2 : 0.35),
                  width: 1,
                ),
              ),
            ),
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                height: height,
                child: Row(
                  children: [
                    if (leadingWidget != null) ...[
                      leadingWidget,
                      const SizedBox(width: AppLayout.spaceXS),
                    ],
                    Expanded(child: headerContent),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
