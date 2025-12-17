import 'package:local_auth/local_auth.dart' as local_auth;
import 'package:flutter/services.dart';

class AuthService {
  static final _auth = local_auth.LocalAuthentication();

  static Future<bool> hasBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Provide credentials to access your notes',
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}
