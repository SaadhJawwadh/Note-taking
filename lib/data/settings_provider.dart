import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NoteViewMode { list, masonryGrid, uniformGrid }

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

  NoteViewMode _noteViewMode = NoteViewMode.masonryGrid;

  NoteViewMode get noteViewMode => _noteViewMode;
  
  // Legacy getter for broader compatibility
  bool get isGridView => _noteViewMode == NoteViewMode.masonryGrid || _noteViewMode == NoteViewMode.uniformGrid;

  bool _showFinancialManager = false;
  bool get showFinancialManager => _showFinancialManager;

  bool _showFileConverter = false;
  bool get showFileConverter => _showFileConverter;

  bool _isConverterLite = true;
  bool get isConverterLite => _isConverterLite;

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

  // Period Tracker & App Lock
  bool _isPeriodTrackerEnabled = false;
  bool get isPeriodTrackerEnabled => _isPeriodTrackerEnabled;

  bool _appLockEnabled = false;
  bool get appLockEnabled => _appLockEnabled;

  bool _useBiometrics = false;
  bool get useBiometrics => _useBiometrics;

  String _discreetNotificationText = 'Check the app';
  String get discreetNotificationText => _discreetNotificationText;

  List<String> _customExpenseRules = [];
  List<String> get customExpenseRules => _customExpenseRules;

  List<String> _customIncomeRules = [];
  List<String> get customIncomeRules => _customIncomeRules;

  // File Converter Settings
  String _preferredVideoFormat = 'mp4';
  String get preferredVideoFormat => _preferredVideoFormat;

  String _preferredImageFormat = 'jpg';
  String get preferredImageFormat => _preferredImageFormat;

  String _videoResolutionLimit = 'Original';
  String get videoResolutionLimit => _videoResolutionLimit;

  bool _keepMetadata = false;
  bool get keepMetadata => _keepMetadata;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _textSize = prefs.getDouble('textSize') ?? 16.0;
    _fontFamily = prefs.getString('fontFamily') ?? 'Rubik';
    final viewModeIndex = prefs.getInt('noteViewMode');
    if (viewModeIndex != null && viewModeIndex >= 0 && viewModeIndex < NoteViewMode.values.length) {
      _noteViewMode = NoteViewMode.values[viewModeIndex];
    } else {
      final legacyGrid = prefs.getBool('isGridView') ?? true;
      _noteViewMode = legacyGrid ? NoteViewMode.masonryGrid : NoteViewMode.list;
    }
    _showFinancialManager = prefs.getBool('showFinancialManager') ?? false;
    _showFileConverter = prefs.getBool('showFileConverter') ?? false;
    _isConverterLite = prefs.getBool('isConverterLite') ?? true;
    _currency = prefs.getString('currency') ?? 'LKR';

    _autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;
    _autoBackupFrequency = prefs.getString('autoBackupFrequency') ?? 'daily';
    _autoBackupPath = prefs.getString('autoBackupPath');
    _lastAutoBackupTime = prefs.getString('lastAutoBackupTime');

    _isPeriodTrackerEnabled = prefs.getBool('isPeriodTrackerEnabled') ?? false;
    _appLockEnabled = prefs.getBool('appLockEnabled') ?? false;
    _useBiometrics = prefs.getBool('useBiometrics') ?? false;
    _discreetNotificationText =
        prefs.getString('discreetNotificationText') ?? 'Check the app';

    _customExpenseRules = prefs.getStringList('customExpenseRules') ?? [];
    _customIncomeRules = prefs.getStringList('customIncomeRules') ?? [];

    _preferredVideoFormat = prefs.getString('preferredVideoFormat') ?? 'mp4';
    _preferredImageFormat = prefs.getString('preferredImageFormat') ?? 'jpg';
    _videoResolutionLimit = prefs.getString('videoResolutionLimit') ?? 'Original';
    _keepMetadata = prefs.getBool('keepMetadata') ?? false;

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

  Future<void> addCustomRule(String rule, {required bool isExpense}) async {
    final prefs = await SharedPreferences.getInstance();
    if (isExpense) {
      if (!_customExpenseRules.contains(rule)) {
        _customExpenseRules.add(rule);
        await prefs.setStringList('customExpenseRules', _customExpenseRules);
      }
    } else {
      if (!_customIncomeRules.contains(rule)) {
        _customIncomeRules.add(rule);
        await prefs.setStringList('customIncomeRules', _customIncomeRules);
      }
    }
    notifyListeners();
  }

  Future<void> removeCustomRule(String rule, {required bool isExpense}) async {
    final prefs = await SharedPreferences.getInstance();
    if (isExpense) {
      _customExpenseRules.remove(rule);
      await prefs.setStringList('customExpenseRules', _customExpenseRules);
    } else {
      _customIncomeRules.remove(rule);
      await prefs.setStringList('customIncomeRules', _customIncomeRules);
    }
    notifyListeners();
  }

  Future<void> setShowFileConverter(bool show) async {
    _showFileConverter = show;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showFileConverter', show);
    notifyListeners();
  }

  Future<void> setIsConverterLite(bool isLite) async {
    _isConverterLite = isLite;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isConverterLite', isLite);
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

  Future<void> setNoteViewMode(NoteViewMode mode) async {
    _noteViewMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('noteViewMode', mode.index);
    notifyListeners();
  }

  // Legacy fallback
  Future<void> setIsGridView(bool isGrid) async {
    await setNoteViewMode(isGrid ? NoteViewMode.masonryGrid : NoteViewMode.list);
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

  Future<void> setIsPeriodTrackerEnabled(bool enabled) async {
    _isPeriodTrackerEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPeriodTrackerEnabled', enabled);
    notifyListeners();
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    _appLockEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('appLockEnabled', enabled);
    notifyListeners();
  }

  Future<void> setUseBiometrics(bool use) async {
    _useBiometrics = use;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useBiometrics', use);
    notifyListeners();
  }

  Future<void> setDiscreetNotificationText(String text) async {
    _discreetNotificationText = text;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('discreetNotificationText', text);
    notifyListeners();
  }

  Future<void> setPreferredVideoFormat(String format) async {
    _preferredVideoFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferredVideoFormat', format);
    notifyListeners();
  }

  Future<void> setPreferredImageFormat(String format) async {
    _preferredImageFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferredImageFormat', format);
    notifyListeners();
  }

  Future<void> setVideoResolutionLimit(String limit) async {
    _videoResolutionLimit = limit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('videoResolutionLimit', limit);
    notifyListeners();
  }

  Future<void> setKeepMetadata(bool keep) async {
    _keepMetadata = keep;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keepMetadata', keep);
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
        'isGridView': isGridView, // Legacy export support
        'noteViewMode': _noteViewMode.index,
        'showFinancialManager': _showFinancialManager,
        'showFileConverter': _showFileConverter,
        'isConverterLite': _isConverterLite,
        'currency': _currency,
        'isPeriodTrackerEnabled': _isPeriodTrackerEnabled,
        'appLockEnabled': _appLockEnabled,
        'useBiometrics': _useBiometrics,
        'discreetNotificationText': _discreetNotificationText,
        'preferredVideoFormat': _preferredVideoFormat,
        'preferredImageFormat': _preferredImageFormat,
        'videoResolutionLimit': _videoResolutionLimit,
        'keepMetadata': _keepMetadata,
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
      if (map.containsKey('noteViewMode')) {
        final viewModeIdx = (map['noteViewMode'] as num?)?.toInt() ?? NoteViewMode.masonryGrid.index;
        if (viewModeIdx >= 0 && viewModeIdx < NoteViewMode.values.length) {
          await setNoteViewMode(NoteViewMode.values[viewModeIdx]);
        }
      } else if (map.containsKey('isGridView')) {
        final grid = map['isGridView'];
        if (grid is bool) await setIsGridView(grid);
      }
      if (map.containsKey('showFinancialManager')) {
        final show = map['showFinancialManager'];
        if (show is bool) {
          _showFinancialManager = show;
        }
      }
      if (map.containsKey('showFileConverter')) {
        final show = map['showFileConverter'];
        if (show is bool) {
          _showFileConverter = show;
        }
      }
      if (map.containsKey('isConverterLite')) {
        final isLite = map['isConverterLite'];
        if (isLite is bool) {
          _isConverterLite = isLite;
        }
      }
      if (map.containsKey('currency')) {
        final curr = map['currency'];
        if (curr is String && curr.isNotEmpty) await setCurrency(curr);
      }
      if (map.containsKey('isPeriodTrackerEnabled')) {
        final ptEnabled = map['isPeriodTrackerEnabled'];
        if (ptEnabled is bool) await setIsPeriodTrackerEnabled(ptEnabled);
      }
      // Security settings (appLockEnabled, useBiometrics) are intentionally
      // excluded from restore to prevent bypass via crafted backup files.
      // Users must configure these manually after a restore.
      if (map.containsKey('discreetNotificationText')) {
        final txt = map['discreetNotificationText'];
        if (txt is String && txt.isNotEmpty) {
          await setDiscreetNotificationText(txt);
        }
      }
      if (map.containsKey('preferredVideoFormat')) {
        final val = map['preferredVideoFormat'];
        if (val is String) await setPreferredVideoFormat(val);
      }
      if (map.containsKey('preferredImageFormat')) {
        final val = map['preferredImageFormat'];
        if (val is String) await setPreferredImageFormat(val);
      }
      if (map.containsKey('videoResolutionLimit')) {
        final val = map['videoResolutionLimit'];
        if (val is String) await setVideoResolutionLimit(val);
      }
      if (map.containsKey('keepMetadata')) {
        final val = map['keepMetadata'];
        if (val is bool) await setKeepMetadata(val);
      }
    } catch (_) {
      // Silently ignore malformed backup settings; existing values are kept.
    }
  }
}
