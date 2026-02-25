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

  // Auto-backup (device-specific — excluded from backup export/restore)
  bool _autoBackupEnabled = false;
  bool get autoBackupEnabled => _autoBackupEnabled;

  String _autoBackupFrequency = 'daily';
  String get autoBackupFrequency => _autoBackupFrequency;

  String? _autoBackupPath;
  String? get autoBackupPath => _autoBackupPath;

  String? _lastAutoBackupTime;
  String? get lastAutoBackupTime => _lastAutoBackupTime;

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

    _autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;
    _autoBackupFrequency = prefs.getString('autoBackupFrequency') ?? 'daily';
    _autoBackupPath = prefs.getString('autoBackupPath');
    _lastAutoBackupTime = prefs.getString('lastAutoBackupTime');

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

  Future<void> setAutoBackupEnabled(bool enabled) async {
    _autoBackupEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoBackupEnabled', enabled);
    notifyListeners();
  }

  Future<void> setAutoBackupFrequency(String freq) async {
    _autoBackupFrequency = freq;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('autoBackupFrequency', freq);
    notifyListeners();
  }

  Future<void> setAutoBackupPath(String? path) async {
    _autoBackupPath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString('autoBackupPath', path);
    } else {
      await prefs.remove('autoBackupPath');
    }
    notifyListeners();
  }

  Future<void> setLastAutoBackupTime(String? time) async {
    _lastAutoBackupTime = time;
    final prefs = await SharedPreferences.getInstance();
    if (time != null) {
      await prefs.setString('lastAutoBackupTime', time);
    } else {
      await prefs.remove('lastAutoBackupTime');
    }
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

  Map<String, dynamic> toBackupMap() => {
        'textSize': _textSize,
        'themeMode': _getIntFromThemeMode(_themeMode),
        'fontFamily': _fontFamily,
        'isGridView': _isGridView,
        'showFinancialManager': _showFinancialManager,
        'currency': _currency,
      };

  Future<void> restoreFromBackupMap(Map<String, dynamic> map) async {
    try {
      if (map.containsKey('textSize')) {
        final size = (map['textSize'] as num?)?.toDouble() ?? 16.0;
        if (size >= 8.0 && size <= 32.0) await setTextSize(size);
      }
      if (map.containsKey('themeMode')) {
        final idx = (map['themeMode'] as num?)?.toInt() ?? 0;
        await setThemeMode(_getThemeModeFromInt(idx));
      }
      if (map.containsKey('fontFamily')) {
        final font = map['fontFamily'];
        if (font is String && font.isNotEmpty) await setFontFamily(font);
      }
      if (map.containsKey('isGridView')) {
        final grid = map['isGridView'];
        if (grid is bool) await setIsGridView(grid);
      }
      if (map.containsKey('showFinancialManager')) {
        final show = map['showFinancialManager'];
        if (show is bool) await setShowFinancialManager(show);
      }
      if (map.containsKey('currency')) {
        final curr = map['currency'];
        if (curr is String && curr.isNotEmpty) await setCurrency(curr);
      }
    } catch (_) {
      // Silently ignore malformed backup settings; existing values are kept.
    }
  }
}
