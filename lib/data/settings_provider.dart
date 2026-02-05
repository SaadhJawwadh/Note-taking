import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  double _textSize = 16.0;
  ThemeMode _themeMode = ThemeMode.system;

  double get textSize => _textSize;
  ThemeMode get themeMode => _themeMode;

  String get textSizeLabel {
    if (_textSize == 14.0) return 'Small';
    if (_textSize == 20.0) return 'Large';
    return 'Medium';
  }

  String _fontFamily = 'Rubik';
  String get fontFamily => _fontFamily;

  bool _isGridView = true;

  bool get isGridView => _isGridView;

  bool _showFinancialManager = false;
  bool get showFinancialManager => _showFinancialManager;

  String _currency = 'LKR';
  String get currency => _currency;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _textSize = prefs.getDouble('textSize') ?? 16.0;
    _fontFamily = prefs.getString('fontFamily') ?? 'Rubik';
    _isGridView = prefs.getBool('isGridView') ?? true;
    _showFinancialManager = prefs.getBool('showFinancialManager') ?? false;
    _currency = prefs.getString('currency') ?? 'LKR';

    final themeIndex = prefs.getInt('themeMode') ?? 0;
    _themeMode = _getThemeModeFromInt(themeIndex);

    notifyListeners();
  }

  Future<void> setCurrency(String curr) async {
    _currency = curr;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', curr);
    notifyListeners();
  }

  Future<void> setTextSize(double size) async {
    _textSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textSize', size);
    notifyListeners();
  }

  Future<void> setFontFamily(String font) async {
    _fontFamily = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontFamily', font);
    notifyListeners();
  }

  Future<void> setIsGridView(bool isGrid) async {
    _isGridView = isGrid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGridView', isGrid);
    notifyListeners();
  }

  Future<void> setShowFinancialManager(bool show) async {
    _showFinancialManager = show;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showFinancialManager', show);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _getIntFromThemeMode(mode));
    notifyListeners();
  }

  ThemeMode _getThemeModeFromInt(int value) {
    switch (value) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  int _getIntFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 1;
      case ThemeMode.dark:
        return 2;
      default:
        return 0;
    }
  }
}
