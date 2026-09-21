import 'package:flutter/material.dart';
import '../theme/app_layout.dart';

/// Material 3 Expressive Floating Toolbar.
///
/// Implements the official Google Material 3 specification:
/// - Shape: Fully rounded stadium pill (`StadiumBorder` / `radiusMAX`).
/// - Height: 56–64dp.
/// - Margins: 16dp minimum clearance from window boundaries.
/// - Touch Targets: Enforces >= 48x48dp interactive bounding boxes.
/// - Elevation: Level 2 / Level 3 soft ambient shadow.
/// - Border: 1.0dp subtle boundary (`outlineVariant` with 35% alpha).
/// - Color Roles: Standard (`surfaceContainerHigh`) or Vibrant (`secondaryContainer`).
class ExpressiveFloatingToolbar extends StatelessWidget {
  final List<Widget> children;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isVibrant;
  final bool isScrollable;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const ExpressiveFloatingToolbar({
    super.key,
    required this.children,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.padding,
    this.margin,
    this.isVibrant = false,
    this.isScrollable = false,
    this.mainAxisSize = MainAxisSize.min,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color effectiveBackground = backgroundColor ??
        (isVibrant
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerHigh);

    final Color effectiveForeground = foregroundColor ??
        (isVibrant
            ? colorScheme.onSecondaryContainer
            : colorScheme.onSurface);

    Widget content = Row(
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );

    if (isScrollable) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    return Semantics(
      container: true,
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        constraints: const BoxConstraints(
          minHeight: 56.0,
          maxHeight: 64.0,
        ),
        decoration: BoxDecoration(
          color: effectiveBackground,
          borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: 1.0,
          ),
          boxShadow: AppLayout.softShadow(context),
        ),
        child: IconTheme(
          data: IconThemeData(
            color: effectiveForeground,
            size: 24.0,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: content,
          ),
        ),
      ),
    );
  }

  /// Helper to provide intentional M3 whitespace grouping between toolbar button clusters.
  /// In Material 3 Expressive, visual grouping is achieved through whitespace gaps
  /// rather than 1px hairline rules.
  static Widget spacer({double width = 8.0}) {
    return SizedBox(width: width);
  }

  /// Legacy helper for toolbar button clustering.
  /// Maintained for backwards-compatibility; now renders an intentional M3 whitespace spacer
  /// instead of a 1px vertical hairline rule.
  static Widget divider(BuildContext context, {double height = 24.0, double width = 8.0}) {
    return SizedBox(width: width);
  }

  /// Helper to create an accessible toolbar icon button with guaranteed >=48x48dp bounds.
  static Widget actionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? color,
    bool isSelected = false,
    Widget? customIcon,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final Color buttonColor = color ??
            (isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant);

        return IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
          padding: const EdgeInsets.all(8.0),
          icon: customIcon ?? Icon(icon, size: 24.0, color: buttonColor),
        );
      },
    );
  }

  /// Helper to create an accessible toolbar button with an icon and label text.
  static Widget labeledActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
    bool isSelected = false,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final Color buttonColor = color ??
            (isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant);

        return TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20.0, color: buttonColor),
          label: Text(
            label,
            style: TextStyle(
              color: buttonColor,
              fontWeight: FontWeight.w600,
              fontSize: 13.0,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            minimumSize: const Size(48.0, 48.0),
            shape: const StadiumBorder(),
          ),
        );
      },
    );
  }
}
