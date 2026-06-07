import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../data/settings_provider.dart';

class AppLockScreen extends StatefulWidget {
  final Widget child;

  const AppLockScreen({super.key, required this.child});
  
  static final ValueNotifier<bool> sessionAuthenticated = ValueNotifier<bool>(false);
  static bool _ignoreNextResumeLock = false;

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

  static const MethodChannel _channel = MethodChannel('com.example.note_taking_app/device_lock');

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
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      if (value.isNotEmpty) {
        AppLockScreen.unlockSession();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final media = await ReceiveSharingIntent.instance.getInitialMedia();
        if (media.isNotEmpty) {
          AppLockScreen.unlockSession();
        }
      } catch (e) {
        debugPrint('Error checking initial media on lock screen start: $e');
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
    _intentDataStreamSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    AppLockScreen.sessionAuthenticated.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isBackground = state != AppLifecycleState.resumed;
    if (mounted) {
      setState(() {
        _isInBackground = isBackground;
      });
    }

    if (_isAuthenticating) {
      // Ignore lifecycle changes caused by the biometric authentication dialog itself
      return;
    }
    setState(() {
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
    });

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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline,
                  size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'App Locked',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              if (!_isInBackground)
                ElevatedButton(
                  onPressed: () => _checkAuth(context),
                  child: const Text('Unlock'),
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
            child: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 80, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 24),
                    Text(
                      'App Locked',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
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
