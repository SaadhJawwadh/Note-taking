import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/features/settings/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Modular Sub-Feature Settings Tests', () {
    late SettingsProvider settings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settings = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('Default values for modular sub-features are backward compatible', () {
      expect(settings.enableSmsImport, isTrue);
      expect(settings.enableBudgetsAndAnalytics, isTrue);
      expect(settings.enableRecurringRules, isTrue);
      expect(settings.showTagFilterBar, isTrue);
      expect(settings.minimalEditorMode, isFalse);
    });

    test('setEnableSmsImport updates value and persists across reloads', () async {
      await settings.setEnableSmsImport(false);
      expect(settings.enableSmsImport, isFalse);

      final reloaded = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(reloaded.enableSmsImport, isFalse);
    });

    test('setEnableBudgetsAndAnalytics updates value and persists across reloads', () async {
      await settings.setEnableBudgetsAndAnalytics(false);
      expect(settings.enableBudgetsAndAnalytics, isFalse);

      final reloaded = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(reloaded.enableBudgetsAndAnalytics, isFalse);
    });

    test('setEnableRecurringRules updates value and persists across reloads', () async {
      await settings.setEnableRecurringRules(false);
      expect(settings.enableRecurringRules, isFalse);

      final reloaded = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(reloaded.enableRecurringRules, isFalse);
    });

    test('setShowTagFilterBar updates value and persists across reloads', () async {
      await settings.setShowTagFilterBar(false);
      expect(settings.showTagFilterBar, isFalse);

      final reloaded = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(reloaded.showTagFilterBar, isFalse);
    });

    test('setMinimalEditorMode updates value and persists across reloads', () async {
      await settings.setMinimalEditorMode(true);
      expect(settings.minimalEditorMode, isTrue);

      final reloaded = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(reloaded.minimalEditorMode, isTrue);
    });

    test('toBackupMap and restoreFromBackupMap preserve modular sub-features', () async {
      await settings.setEnableSmsImport(false);
      await settings.setEnableBudgetsAndAnalytics(false);
      await settings.setEnableRecurringRules(false);
      await settings.setShowTagFilterBar(false);
      await settings.setMinimalEditorMode(true);

      final backup = settings.toBackupMap();
      expect(backup['enableSmsImport'], isFalse);
      expect(backup['enableBudgetsAndAnalytics'], isFalse);
      expect(backup['enableRecurringRules'], isFalse);
      expect(backup['showTagFilterBar'], isFalse);
      expect(backup['minimalEditorMode'], isTrue);

      // Restore into a fresh settings instance with default true/false
      SharedPreferences.setMockInitialValues({});
      final freshSettings = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(freshSettings.enableSmsImport, isTrue);

      await freshSettings.restoreFromBackupMap(backup);
      expect(freshSettings.enableSmsImport, isFalse);
      expect(freshSettings.enableBudgetsAndAnalytics, isFalse);
      expect(freshSettings.enableRecurringRules, isFalse);
      expect(freshSettings.showTagFilterBar, isFalse);
      expect(freshSettings.minimalEditorMode, isTrue);
    });
  });

  group('Tab Selection Fallback Logic Tests', () {
    String resolveEffectiveTab({
      required String selectedTab,
      required bool showBudgets,
      required bool showSplitBills,
    }) {
      return (showBudgets || selectedTab != 'Budgets') &&
              (showSplitBills || selectedTab != 'Split Bills')
          ? selectedTab
          : 'Ledger';
    }

    test('Falls back to Ledger if active tab is Budgets but Budgets is disabled', () {
      final tab = resolveEffectiveTab(
        selectedTab: 'Budgets',
        showBudgets: false,
        showSplitBills: true,
      );
      expect(tab, 'Ledger');
    });

    test('Falls back to Ledger if active tab is Split Bills but Split Bills is disabled', () {
      final tab = resolveEffectiveTab(
        selectedTab: 'Split Bills',
        showBudgets: true,
        showSplitBills: false,
      );
      expect(tab, 'Ledger');
    });

    test('Preserves active tab when respective sub-feature is enabled', () {
      expect(
        resolveEffectiveTab(
          selectedTab: 'Budgets',
          showBudgets: true,
          showSplitBills: false,
        ),
        'Budgets',
      );
      expect(
        resolveEffectiveTab(
          selectedTab: 'Split Bills',
          showBudgets: false,
          showSplitBills: true,
        ),
        'Split Bills',
      );
      expect(
        resolveEffectiveTab(
          selectedTab: 'Ledger',
          showBudgets: false,
          showSplitBills: false,
        ),
        'Ledger',
      );
    });
  });
}
