import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import '../theme/app_layout.dart';

/// Navigation helpers implementing the Material Expressive motion system.
///
/// Card-morph launches (note cards, FABs) keep using [OpenContainer]; every
/// other forward navigation should use [AppRoute.push] so drill-ins get the
/// M3 shared-axis transition instead of the global fade-through.
class AppRoute {
  AppRoute._();

  /// Pushes [page] with a horizontal shared-axis transition (drill-in).
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(sharedAxis<T>(page));
  }

  /// A horizontal shared-axis route, for use where a [Route] is needed.
  static Route<T> sharedAxis<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: AppLayout.animDefault,
      reverseTransitionDuration: AppLayout.animDefault,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
    );
  }
}
