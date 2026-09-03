import 'package:flutter/material.dart';
import '../theme/app_layout.dart';

/// Semantic types for [AppSnackBar].
enum SnackBarType {
  info,
  success,
  error,
  warning,
}

/// Standardized Material 3 Expressive floating SnackBar component.
///
/// Enforces consistent border radius, floating behavior, semantic iconography,
/// and typography across all user-facing notifications.
class AppSnackBar {
  AppSnackBar._();

  /// Builds a standardized [SnackBar] widget.
  static SnackBar build(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? iconColor,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
    SnackBarType type = SnackBarType.info,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    IconData effectiveIcon;
    Color effectiveIconColor;

    switch (type) {
      case SnackBarType.success:
        effectiveIcon = icon ?? Icons.check_circle_rounded;
        effectiveIconColor = iconColor ?? colorScheme.primary;
        break;
      case SnackBarType.error:
        effectiveIcon = icon ?? Icons.error_outline_rounded;
        effectiveIconColor = iconColor ?? colorScheme.error;
        break;
      case SnackBarType.warning:
        effectiveIcon = icon ?? Icons.warning_amber_rounded;
        effectiveIconColor = iconColor ?? colorScheme.tertiary;
        break;
      case SnackBarType.info:
        effectiveIcon = icon ?? Icons.info_outline_rounded;
        effectiveIconColor = iconColor ?? colorScheme.onInverseSurface;
        break;
    }

    return SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      action: action,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusM),
      ),
      content: Row(
        children: [
          Icon(effectiveIcon, size: 20, color: effectiveIconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onInverseSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Displays an [AppSnackBar] on the active [ScaffoldMessenger].
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? iconColor,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
    SnackBarType type = SnackBarType.info,
    bool clearPrevious = true,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    if (clearPrevious) {
      messenger.clearSnackBars();
    }
    messenger.showSnackBar(
      build(
        context,
        message: message,
        icon: icon,
        iconColor: iconColor,
        action: action,
        duration: duration,
        type: type,
      ),
    );
  }

  /// Displays a success [AppSnackBar] with [Icons.check_circle_rounded].
  static void showSuccess(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
    bool clearPrevious = true,
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.success,
      action: action,
      duration: duration,
      clearPrevious: clearPrevious,
    );
  }

  /// Displays an error [AppSnackBar] with [Icons.error_outline_rounded].
  static void showError(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
    bool clearPrevious = true,
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.error,
      action: action,
      duration: duration,
      clearPrevious: clearPrevious,
    );
  }

  /// Displays an informational [AppSnackBar] with [Icons.info_outline_rounded].
  static void showInfo(
    BuildContext context, {
    required String message,
    IconData? icon,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
    bool clearPrevious = true,
  }) {
    show(
      context,
      message: message,
      icon: icon,
      type: SnackBarType.info,
      action: action,
      duration: duration,
      clearPrevious: clearPrevious,
    );
  }

  /// Displays a standardized [SnackBar] through a direct [ScaffoldMessengerState].
  static void showWithMessenger(
    ScaffoldMessengerState messenger, {
    required BuildContext context,
    required String message,
    IconData? icon,
    Color? iconColor,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
    SnackBarType type = SnackBarType.info,
    bool clearPrevious = true,
  }) {
    if (clearPrevious) {
      messenger.clearSnackBars();
    }
    messenger.showSnackBar(
      build(
        context,
        message: message,
        icon: icon,
        iconColor: iconColor,
        action: action,
        duration: duration,
        type: type,
      ),
    );
  }
}
