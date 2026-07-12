import 'package:flutter/material.dart';

/// App-level keys so services and popped routes can reach the navigator and
/// snackbars without a local BuildContext (notification taps, post-pop undo).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
