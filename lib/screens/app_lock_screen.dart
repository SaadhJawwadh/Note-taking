import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';

class AppLockScreen extends StatefulWidget {
  final Widget child;

  const AppLockScreen({super.key, required this.child});

  @override
  AppLockScreenState createState() => AppLockScreenState();
}

class AppLockScreenState extends State<AppLockScreen>
    with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;

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
    if (state == AppLifecycleState.paused) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_isAuthenticated && !_isAuthenticating) {
        _checkAuth(context);
      }
    }
  }

  Future<void> _checkAuth(BuildContext context) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!settings.appLockEnabled) {
      setState(() {
        _isAuthenticated = true;
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
    });

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
          _isAuthenticated = didAuthenticate;
        });
      }
    } catch (e) {
      debugPrint('Authentication error: $e');
      // On error, let them try again or fall back securely
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

    if (!settings.appLockEnabled || _isAuthenticated) {
      return widget.child;
    }

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
            ElevatedButton(
              onPressed: () => _checkAuth(context),
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
