import 'package:flutter/material.dart';
import '../theme/app_layout.dart';

/// Reusable AppCard widget providing single-source-of-truth styling for card containers.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final BorderSide? border;
  final double? borderRadius;
  final BorderRadiusGeometry? borderRadiusGeometry;
  final List<BoxShadow>? boxShadow;
  final bool isFrosted;
  final double blurSigma;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.borderRadiusGeometry,
    this.boxShadow,
  })  : isFrosted = false,
        blurSigma = 0.0;

  /// Material 3 Tonal Card constructor with subtle container tint & matching border.
  factory AppCard.tonal({
    Key? key,
    required Widget child,
    required Color color,
    Color? borderColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    double? borderRadius,
    BorderRadiusGeometry? borderRadiusGeometry,
    List<BoxShadow>? boxShadow,
  }) {
    return AppCard(
      key: key,
      padding: padding,
      margin: margin,
      onTap: onTap,
      onLongPress: onLongPress,
      backgroundColor: color,
      border: BorderSide(
        color: borderColor ?? color.withValues(alpha: 0.35),
        width: 1.0,
      ),
      borderRadius: borderRadius,
      borderRadiusGeometry: borderRadiusGeometry,
      boxShadow: boxShadow,
      child: child,
    );
  }

  /// Material 3 Surface Card constructor (formerly frosted, now pure solid M3 surface container).
  const AppCard.frosted({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.borderRadiusGeometry,
    this.boxShadow,
    this.blurSigma = 0.0,
  }) : isFrosted = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = backgroundColor ??
        (isFrosted
            ? (isDark
                ? theme.colorScheme.surfaceContainerHigh
                : theme.colorScheme.surfaceContainer)
            : theme.colorScheme.surfaceContainerHigh);
    final effectiveBorder = border ??
        (isFrosted
            ? BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.50),
                width: 1.0,
              )
            : null);
    final effectiveBorderRadius = borderRadiusGeometry ??
        BorderRadius.circular(borderRadius ?? AppLayout.radiusL);

    Widget cardPadding = Padding(
      padding: padding ?? AppLayout.paddingAllL,
      child: child,
    );

    Widget innerContent = Material(
      color: effectiveColor,
      borderRadius: effectiveBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: (onTap != null || onLongPress != null)
          ? InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              highlightColor: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: effectiveBorderRadius is BorderRadius ? effectiveBorderRadius : null,
              child: cardPadding,
            )
          : cardPadding,
    );

    if (effectiveBorder != null || boxShadow != null) {
      innerContent = Container(
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          border: effectiveBorder != null ? Border.fromBorderSide(effectiveBorder) : null,
          boxShadow: boxShadow,
        ),
        child: innerContent,
      );
    }

    if (margin != null) {
      innerContent = Padding(
        padding: margin!,
        child: innerContent,
      );
    }

    return innerContent;
  }
}
