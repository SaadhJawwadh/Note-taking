import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';

class AppLockScreen extends StatefulWidget {
  final Widget child;

  const AppLockScreen({super.key, required this.child});
  
  // Static helper to manually unlock the session (useful for sharing)
  static void unlockSession() {
    AppLockScreenState._isSessionAuthenticated = true;
  }

  @override
  AppLockScreenState createState() => AppLockScreenState();
}

class AppLockScreenState extends State<AppLockScreen>
    with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();
  
  // Static to persist across widget rebuilds in the same app session
  static bool _isSessionAuthenticated = false;
  bool _isInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isInBackground = state != AppLifecycleState.resumed;
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        // App went to the background, so require authentication again on resume
        _isSessionAuthenticated = false;
      }
    });

    if (state == AppLifecycleState.resumed && !_isSessionAuthenticated) {
      // Prompt for authentication immediately when coming back to foreground
      _checkAuth(context);
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

    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (mounted) {
        setState(() {
          _isSessionAuthenticated = didAuthenticate;
        });
      }
    } catch (e) {
      debugPrint('Authentication error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    if (!settings.appLockEnabled) {
      return widget.child;
    }

    if (_isInBackground || !_isSessionAuthenticated) {
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

    return widget.child;
  }
}
