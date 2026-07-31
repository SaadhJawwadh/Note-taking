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
  final List<BoxShadow>? boxShadow;

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
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = backgroundColor ?? theme.colorScheme.surfaceContainerHigh;
    final effectiveRadius = borderRadius ?? AppLayout.radiusL;

    Widget cardPadding = Padding(
      padding: padding ?? AppLayout.paddingAllL,
      child: child,
    );

    Widget content = Material(
      color: effectiveColor,
      borderRadius: BorderRadius.circular(effectiveRadius),
      clipBehavior: Clip.antiAlias,
      child: (onTap != null || onLongPress != null)
          ? InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              highlightColor: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(effectiveRadius),
              child: cardPadding,
            )
          : cardPadding,
    );

    if (border != null || boxShadow != null) {
      content = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: border != null ? Border.fromBorderSide(border!) : null,
          boxShadow: boxShadow,
        ),
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(
        padding: margin!,
        child: content,
      );
    }

    return content;
  }
}
