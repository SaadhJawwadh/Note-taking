import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/local_ai_service.dart';
import '../services/sms_service.dart';
import '../screens/app_lock_screen.dart';
import 'dart:convert';

enum NoteViewMode { list, grid }

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

  bool _useDynamicColor = true;
  bool get useDynamicColor => _useDynamicColor;

  NoteViewMode _noteViewMode = NoteViewMode.grid;

  NoteViewMode get noteViewMode => _noteViewMode;
  
  // Legacy getter for broader compatibility
  bool get isGridView => _noteViewMode == NoteViewMode.grid;

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

  // Period Tracker & App Lock
  bool _isPeriodTrackerEnabled = false;
  bool get isPeriodTrackerEnabled => _isPeriodTrackerEnabled;

  bool _appLockEnabled = false;
  bool get appLockEnabled => _appLockEnabled;

  bool _useBiometrics = false;
  bool get useBiometrics => _useBiometrics;

  int _appLockTimeout = 0; // in seconds
  int get appLockTimeout => _appLockTimeout;

  String _discreetNotificationText = 'Check the app';
  String get discreetNotificationText => _discreetNotificationText;

  List<String> _customExpenseRules = [];
  List<String> get customExpenseRules => _customExpenseRules;

  List<String> _customIncomeRules = [];
  List<String> get customIncomeRules => _customIncomeRules;

  bool _useOnDeviceAi = false;
  bool get useOnDeviceAi => _useOnDeviceAi;

  bool _isDeviceAiSupported = false;
  bool get isDeviceAiSupported => _isDeviceAiSupported;

  bool _hasSeenOnboarding = false;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _dailySyncEnabled = false;
  bool get dailySyncEnabled => _dailySyncEnabled;

  String _dailySyncTime = '20:00';
  String get dailySyncTime => _dailySyncTime;

  String _smsSyncFrequency = '12';
  String get smsSyncFrequency => _smsSyncFrequency;

  String _lastSeenVersion = '';
  String get lastSeenVersion => _lastSeenVersion;

  Map<String, double> _categoryBudgets = {};
  Map<String, double> get categoryBudgets => _categoryBudgets;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _textSize = prefs.getDouble('textSize') ?? 16.0;
    final viewModeIndex = prefs.getInt('noteViewMode');
    if (viewModeIndex != null) {
      if (viewModeIndex >= 0 && viewModeIndex < NoteViewMode.values.length) {
        _noteViewMode = NoteViewMode.values[viewModeIndex];
      } else if (viewModeIndex == 2) {
        _noteViewMode = NoteViewMode.grid;
      } else {
        _noteViewMode = NoteViewMode.grid;
      }
    } else {
      final legacyGrid = prefs.getBool('isGridView') ?? true;
      _noteViewMode = legacyGrid ? NoteViewMode.grid : NoteViewMode.list;
    }
    _showFinancialManager = prefs.getBool('showFinancialManager') ?? false;
    _currency = prefs.getString('currency') ?? 'LKR';

    _autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;
    _autoBackupFrequency = prefs.getString('autoBackupFrequency') ?? 'daily';
    _autoBackupPath = prefs.getString('autoBackupPath');
    _lastAutoBackupTime = prefs.getString('lastAutoBackupTime');

    _isPeriodTrackerEnabled = prefs.getBool('isPeriodTrackerEnabled') ?? false;
    _appLockEnabled = prefs.getBool('appLockEnabled') ?? false;
    _useBiometrics = prefs.getBool('useBiometrics') ?? false;
    _appLockTimeout = prefs.getInt('appLockTimeout') ?? 0;
    _discreetNotificationText =
        prefs.getString('discreetNotificationText') ?? 'Check the app';

    _customExpenseRules = prefs.getStringList('customExpenseRules') ?? [];
    _customIncomeRules = prefs.getStringList('customIncomeRules') ?? [];

    _useOnDeviceAi = prefs.getBool('useOnDeviceAi') ?? false;
    _useDynamicColor = prefs.getBool('useDynamicColor') ?? true;
    _dailySyncEnabled = prefs.getBool('dailySyncEnabled') ?? false;
    _dailySyncTime = prefs.getString('dailySyncTime') ?? '20:00';
    _smsSyncFrequency = prefs.getString('smsSyncFrequency') ?? '12';
    _lastSeenVersion = prefs.getString('lastSeenVersion') ?? '';

    final budgetsStr = prefs.getString('categoryBudgets');
    if (budgetsStr != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(budgetsStr);
        _categoryBudgets = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (_) {}
    }

    _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding_v1') ?? false;

    final themeIndex = prefs.getInt('themeMode') ?? 0;
    _themeMode = _getThemeModeFromInt(themeIndex);

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setHasSeenOnboarding(bool seen) async {
    _hasSeenOnboarding = seen;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding_v1', seen);
    notifyListeners();
  }

  Future<void> setLastSeenVersion(String version) async {
    _lastSeenVersion = version;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSeenVersion', version);
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

  /// Removes every user-added transaction-type rule (restore defaults).
  Future<void> clearCustomRules() async {
    _customExpenseRules = [];
    _customIncomeRules = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('customExpenseRules', []);
    await prefs.setStringList('customIncomeRules', []);
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

  Future<void> setNoteViewMode(NoteViewMode mode) async {
    _noteViewMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('noteViewMode', mode.index);
    notifyListeners();
  }

  // Legacy fallback
  Future<void> setIsGridView(bool isGrid) async {
    await setNoteViewMode(isGrid ? NoteViewMode.grid : NoteViewMode.list);
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

  Future<void> setUseDynamicColor(bool value) async {
    _useDynamicColor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDynamicColor', value);
    notifyListeners();
  }

  Future<void> setIsPeriodTrackerEnabled(bool enabled) async {
    _isPeriodTrackerEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPeriodTrackerEnabled', enabled);
    if (!kIsWeb) {
      if (enabled) {
        AppLockScreen.ignoreNextResumeLock();
        await NotificationService.requestPermissions();
      }
      await NotificationService.schedulePeriodNotifications();
    }
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

  Future<void> setAppLockTimeout(int timeout) async {
    _appLockTimeout = timeout;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appLockTimeout', timeout);
    notifyListeners();
  }

  Future<void> setDiscreetNotificationText(String text) async {
    _discreetNotificationText = text;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('discreetNotificationText', text);
    if (!kIsWeb) {
      await NotificationService.schedulePeriodNotifications();
    }
    notifyListeners();
  }

  Future<void> setDailySyncEnabled(bool enabled) async {
    _dailySyncEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dailySyncEnabled', enabled);
    notifyListeners();
    await SmsService.syncDailySyncSchedule();
  }

  Future<void> setDailySyncTime(String time) async {
    _dailySyncTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dailySyncTime', time);
    notifyListeners();
    await SmsService.syncDailySyncSchedule();
  }

  Future<void> setSmsSyncFrequency(String frequency) async {
    _smsSyncFrequency = frequency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('smsSyncFrequency', frequency);
    notifyListeners();
    await SmsService.syncDailySyncSchedule();
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
        'isGridView': isGridView, // Legacy export support
        'noteViewMode': _noteViewMode.index,
        'showFinancialManager': _showFinancialManager,
        'currency': _currency,
        'isPeriodTrackerEnabled': _isPeriodTrackerEnabled,
        'appLockEnabled': _appLockEnabled,
        'useBiometrics': _useBiometrics,
        'appLockTimeout': _appLockTimeout,
        'discreetNotificationText': _discreetNotificationText,
        'customExpenseRules': _customExpenseRules,
        'customIncomeRules': _customIncomeRules,
        'useOnDeviceAi': _useOnDeviceAi,
        'useDynamicColor': _useDynamicColor,
        'dailySyncEnabled': _dailySyncEnabled,
        'dailySyncTime': _dailySyncTime,
        'smsSyncFrequency': _smsSyncFrequency,
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
      if (map.containsKey('noteViewMode')) {
        final viewModeIdx = (map['noteViewMode'] as num?)?.toInt() ?? NoteViewMode.grid.index;
        if (viewModeIdx >= 0 && viewModeIdx < NoteViewMode.values.length) {
          await setNoteViewMode(NoteViewMode.values[viewModeIdx]);
        } else if (viewModeIdx == 2) {
          await setNoteViewMode(NoteViewMode.grid);
        }
      } else if (map.containsKey('isGridView')) {
        final grid = map['isGridView'];
        if (grid is bool) await setIsGridView(grid);
      }
      if (map.containsKey('showFinancialManager')) {
        final show = map['showFinancialManager'];
        if (show is bool) {
          await setShowFinancialManager(show);
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
      if (map.containsKey('appLockTimeout')) {
        final timeout = (map['appLockTimeout'] as num?)?.toInt();
        if (timeout != null) {
          await setAppLockTimeout(timeout);
        }
      }
      if (map.containsKey('discreetNotificationText')) {
        final txt = map['discreetNotificationText'];
        if (txt is String && txt.isNotEmpty) {
          await setDiscreetNotificationText(txt);
        }
      }
      if (map.containsKey('useOnDeviceAi')) {
        final val = map['useOnDeviceAi'];
        if (val is bool) await setUseOnDeviceAi(val);
      }
      if (map.containsKey('useDynamicColor')) {
        final val = map['useDynamicColor'];
        if (val is bool) await setUseDynamicColor(val);
      }
      if (map.containsKey('customExpenseRules')) {
        final rules = map['customExpenseRules'];
        if (rules is List) {
          final prefs = await SharedPreferences.getInstance();
          _customExpenseRules = List<String>.from(rules);
          await prefs.setStringList('customExpenseRules', _customExpenseRules);
        }
      }
      if (map.containsKey('customIncomeRules')) {
        final rules = map['customIncomeRules'];
        if (rules is List) {
          final prefs = await SharedPreferences.getInstance();
          _customIncomeRules = List<String>.from(rules);
          await prefs.setStringList('customIncomeRules', _customIncomeRules);
        }
      }
      if (map.containsKey('dailySyncEnabled')) {
        final val = map['dailySyncEnabled'];
        if (val is bool) await setDailySyncEnabled(val);
      }
      if (map.containsKey('dailySyncTime')) {
        final val = map['dailySyncTime'];
        if (val is String) await setDailySyncTime(val);
      }
      if (map.containsKey('smsSyncFrequency')) {
        final val = map['smsSyncFrequency'];
        if (val is String) await setSmsSyncFrequency(val);
      }
      notifyListeners();
    } catch (_) {
      // Silently ignore malformed backup settings; existing values are kept.
    }
  }

  Future<void> checkAiCoreSupport(LocalAiService aiService) async {
    try {
      _isDeviceAiSupported = await aiService.isSupported();
    } catch (_) {
      _isDeviceAiSupported = false;
    }
    notifyListeners();
  }

  Future<void> setUseOnDeviceAi(bool enabled) async {
    _useOnDeviceAi = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useOnDeviceAi', enabled);
    notifyListeners();
  }

  Future<void> setCategoryBudget(String category, double amount) async {
    _categoryBudgets[category] = amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('categoryBudgets', jsonEncode(_categoryBudgets));
    notifyListeners();
  }

  Future<void> removeCategoryBudget(String category) async {
    _categoryBudgets.remove(category);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('categoryBudgets', jsonEncode(_categoryBudgets));
    notifyListeners();
  }
}
