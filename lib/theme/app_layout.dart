import 'package:flutter/material.dart';

class AppLayout {
  // Spacing
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 24.0;
  static const double spaceXXL = 32.0;

  // Border Radii
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusMAX = 32.0;

  // Icons
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0; // Added for larger icons
  static const double icon20 = 20.0; // Specific size for selection check

  // Animations
  static const Duration animShort = Duration(milliseconds: 200);
  static const Duration animDefault = Duration(milliseconds: 300);
  static const Duration animLong = Duration(milliseconds: 500);

  // Layout Constraints
  static const double maxContentWidth = 600.0;
  static const double cardElevation = 0.0;
  static const double floatingElevation = 6.0;

  // Padding helper
  static const EdgeInsets paddingAllM = EdgeInsets.all(spaceM);
  static const EdgeInsets paddingAllL = EdgeInsets.all(spaceL);
  static const EdgeInsets paddingHome = EdgeInsets.fromLTRB(spaceL, 0, spaceL, 88);

  /// Theme-driven replacement for ad hoc `BoxShadow(color: Colors.black...)`
  /// blocks scattered across screens — uses the theme's shadow color so it
  /// adapts correctly between light and dark mode.
  static List<BoxShadow> softShadow(BuildContext context, {double blurRadius = 10, Offset offset = const Offset(0, 4)}) {
    return [
      BoxShadow(
        color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
        blurRadius: blurRadius,
        offset: offset,
      ),
    ];
  }
}
