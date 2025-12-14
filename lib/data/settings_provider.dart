import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyTextSize = 'text_size';
  static const String _keyFaceId = 'face_id';
  static const String _keySounds = 'sounds';

  double _textSize = 16.0;
  bool _enableFaceId = false;
  bool _enableSounds = true;

  double get textSize => _textSize;
  bool get enableFaceId => _enableFaceId;
  bool get enableSounds => _enableSounds;

  String get textSizeLabel {
    if (_textSize < 16) return 'Small';
    if (_textSize > 16) return 'Large';
    return 'Medium';
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _textSize = prefs.getDouble(_keyTextSize) ?? 16.0;
    _enableFaceId = prefs.getBool(_keyFaceId) ?? false;
    _enableSounds = prefs.getBool(_keySounds) ?? true;
    notifyListeners();
  }

  Future<void> setTextSize(double size) async {
    _textSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTextSize, size);
    notifyListeners();
  }

  Future<void> setFaceId(bool enabled) async {
    _enableFaceId = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFaceId, enabled);
    notifyListeners();
  }

  Future<void> setSounds(bool enabled) async {
    _enableSounds = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySounds, enabled);
    notifyListeners();
  }
}
