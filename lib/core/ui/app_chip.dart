import 'package:flutter/material.dart';
import '../theme/app_layout.dart';

/// Reusable Chip/Pill component for tags, categories, phase badges, and filters.
class AppChip extends StatelessWidget {
  final String label;
  final Widget? avatar;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Color? backgroundColor;
  final Color? selectedBackgroundColor;
  final Color? textColor;

  const AppChip({
    super.key,
    required this.label,
    this.avatar,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBg = isSelected
        ? (selectedBackgroundColor ?? theme.colorScheme.primaryContainer)
        : (backgroundColor ?? theme.colorScheme.surfaceContainerHighest);

    final effectiveFg = isSelected
        ? theme.colorScheme.onPrimaryContainer
        : (textColor ?? theme.colorScheme.onSurfaceVariant);

    return Material(
      color: effectiveBg,
      borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.spaceM,
            vertical: AppLayout.spaceS,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (avatar != null) ...[
                avatar!,
                const SizedBox(width: AppLayout.spaceS),
              ] else if (icon != null) ...[
                Icon(icon, size: AppLayout.iconS, color: effectiveFg),
                const SizedBox(width: AppLayout.spaceS),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: effectiveFg,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: AppLayout.spaceXS),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close,
                    size: AppLayout.iconS,
                    color: effectiveFg,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
