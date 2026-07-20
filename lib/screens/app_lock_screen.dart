import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../data/settings_provider.dart';
import '../l10n/app_localizations.dart';

class AppLockScreen extends StatefulWidget {
  final Widget child;

  const AppLockScreen({super.key, required this.child});

  static final ValueNotifier<bool> sessionAuthenticated = ValueNotifier<bool>(false);
  static bool _ignoreNextResumeLock = false;

  /// Media shared into the app that hasn't been turned into a note yet —
  /// either because it arrived while locked, or because it arrived at cold
  /// start before HomeScreen mounted. Consumed by HomeScreen.
  static List<SharedMediaFile>? pendingSharedMedia;

  /// Bumped whenever [pendingSharedMedia] is (re)filled so HomeScreen can
  /// consume it immediately instead of waiting for the next resume.
  static final ValueNotifier<int> sharedMediaTick = ValueNotifier<int>(0);

  // Static helper to manually unlock the session (useful for sharing)
  static void unlockSession() {
    sessionAuthenticated.value = true;
  }

  // Static helper to ignore the next lock check when resuming
  static void ignoreNextResumeLock() {
    _ignoreNextResumeLock = true;
  }

  @override
  AppLockScreenState createState() => AppLockScreenState();
}

class AppLockScreenState extends State<AppLockScreen>
    with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();
  
  bool _isInBackground = false;
  bool _isAuthenticating = false;
  DateTime? _backgroundTime;
  StreamSubscription? _intentDataStreamSubscription;

  bool get _isSessionAuthenticated => AppLockScreen.sessionAuthenticated.value;
  set _isSessionAuthenticated(bool val) => AppLockScreen.sessionAuthenticated.value = val;

  static const MethodChannel _channel = MethodChannel('com.saadhjawwadh.notebook/device_lock');

  Future<bool> _isDeviceLockedNative() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      try {
        final bool isLocked = await _channel.invokeMethod('isDeviceLocked');
        return isLocked;
      } catch (e) {
        debugPrint('Error checking device lock status: $e');
        return false;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLockScreen.sessionAuthenticated.addListener(_onAuthChanged);

    // Park shares that arrive while the lock screen is covering the app;
    // HomeScreen isn't mounted then, so its own listener can't see them.
    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      if (files.isEmpty || !mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final isLocked =
          settings.appLockEnabled && !AppLockScreen.sessionAuthenticated.value;
      if (isLocked) {
        AppLockScreen.pendingSharedMedia = files;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Cold-start shares are read here (single source of truth) and handed
      // to HomeScreen via pendingSharedMedia + sharedMediaTick.
      try {
        final media = await ReceiveSharingIntent.instance.getInitialMedia();
        if (media.isNotEmpty) {
          AppLockScreen.pendingSharedMedia = media;
          AppLockScreen.sharedMediaTick.value++;
        }
        unawaited(ReceiveSharingIntent.instance.reset());
      } catch (e) {
        debugPrint('Error checking initial shared media: $e');
      }
      if (mounted) {
        await _checkAuth(context);
      }
    });
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    unawaited(_intentDataStreamSubscription?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    AppLockScreen.sessionAuthenticated.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isAuthenticating) {
      // Ignore lifecycle changes caused by the biometric authentication dialog itself
      // (its system UI briefly backgrounds the app on some platforms/OEM skins).
      return;
    }

    final isBackground = state != AppLifecycleState.resumed;
    if (mounted) {
      setState(() {
        _isInBackground = isBackground;
      });
    }

    if (isBackground) {
      // Record when the app went to the background
      _backgroundTime ??= DateTime.now();
    } else {
      // App is resuming
      if (AppLockScreen._ignoreNextResumeLock) {
        AppLockScreen._ignoreNextResumeLock = false;
      } else if (_backgroundTime != null) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        final elapsed = DateTime.now().difference(_backgroundTime!).inSeconds;
        if (elapsed >= settings.appLockTimeout) {
          _isSessionAuthenticated = false;
        }
      }
      _backgroundTime = null;
    }

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      unawaited(_checkDeviceLockOnBackground());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_checkAuthOnResume());
    }
  }

  Future<void> _checkDeviceLockOnBackground() async {
    final isLocked = await _isDeviceLockedNative();
    if (isLocked) {
      setState(() {
        _isSessionAuthenticated = false;
      });
    }
  }

  Future<void> _checkAuthOnResume() async {
    // Wait 150ms to allow incoming sharing intents to fire and call unlockSession()
    await Future.delayed(const Duration(milliseconds: 150));

    final isLocked = await _isDeviceLockedNative();
    if (isLocked) {
      setState(() {
        _isSessionAuthenticated = false;
      });
    }

    if (!_isSessionAuthenticated) {
      if (mounted) {
        await _checkAuth(context);
      }
    }
  }

  Future<void> _checkAuth(BuildContext context) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    // Bypass if lock is disabled or already authenticated in this session
    if (!settings.appLockEnabled || _isSessionAuthenticated) {
      if (mounted) {
        setState(() {
          _isSessionAuthenticated = true;
        });
      }
      return;
    }

    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: settings.useBiometrics,
        ),
      );

      if (didAuthenticate) {
        if (!kIsWeb && Platform.isAndroid) {
          try {
            await _channel.invokeMethod('resetLockFlag');
          } catch (e) {
            debugPrint('Error invoking resetLockFlag: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _isSessionAuthenticated = didAuthenticate;
        });
      }
    } catch (e) {
      debugPrint('Authentication error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    if (!settings.appLockEnabled) {
      return widget.child;
    }

    if (!_isSessionAuthenticated) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surfaceContainerHigh,
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -150,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        Icons.lock_outline,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)?.appLocked ?? 'App Locked',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    if (!_isInBackground)
                      FilledButton.icon(
                        onPressed: () => _checkAuth(context),
                        icon: const Icon(Icons.fingerprint),
                        label: Text(AppLocalizations.of(context)?.unlock ?? 'Unlock'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isInBackground) {
      return Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 80,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            AppLocalizations.of(context)?.appLocked ?? 'App Locked',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return widget.child;
  }
}
