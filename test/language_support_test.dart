import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note_taking_app/features/settings/providers/settings_provider.dart';
import 'package:note_taking_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Language Support & Localization Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('SettingsProvider language defaults to system and null locale', () {
      final settings = SettingsProvider();
      expect(settings.selectedLanguageCode, equals('system'));
      expect(settings.currentLocale, isNull);
    });

    test('SettingsProvider setSelectedLanguage toggles between en, ta, and system', () async {
      final settings = SettingsProvider();
      bool notified = false;
      settings.addListener(() {
        notified = true;
      });

      // Switch to Tamil
      await settings.setSelectedLanguage('ta');
      expect(settings.selectedLanguageCode, equals('ta'));
      expect(settings.currentLocale, equals(const Locale('ta')));
      expect(notified, isTrue);

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedLanguageCode'), equals('ta'));

      // Switch to English
      notified = false;
      await settings.setSelectedLanguage('en');
      expect(settings.selectedLanguageCode, equals('en'));
      expect(settings.currentLocale, equals(const Locale('en')));
      expect(prefs.getString('selectedLanguageCode'), equals('en'));
      expect(notified, isTrue);

      // Switch back to System
      notified = false;
      await settings.setSelectedLanguage('system');
      expect(settings.selectedLanguageCode, equals('system'));
      expect(settings.currentLocale, isNull);
      expect(prefs.getString('selectedLanguageCode'), isNull);
      expect(notified, isTrue);
    });

    test('SettingsProvider backup and restore preserves selectedLanguageCode', () async {
      final settings = SettingsProvider();
      await settings.setSelectedLanguage('ta');

      final backupMap = settings.toBackupMap();
      expect(backupMap['selectedLanguageCode'], equals('ta'));

      final freshSettings = SettingsProvider();
      await freshSettings.restoreFromBackupMap(backupMap);
      expect(freshSettings.selectedLanguageCode, equals('ta'));
      expect(freshSettings.currentLocale, equals(const Locale('ta')));
    });

    test('AppLocalizations loads English and Tamil bundles with complete keys', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(en.navNotes, equals('Notes'));
      expect(en.navFinances, equals('Finances'));
      expect(en.navTracker, equals('Tracker'));
      expect(en.settingsTitle, equals('Settings'));
      expect(en.newNote, equals('New Note'));
      expect(en.newTransaction, equals('New Transaction'));
      expect(en.savingsGoals, equals('Savings Goals'));
      expect(en.splitBillsTitle, equals('Split Bills'));
      expect(en.save, equals('Save'));
      expect(en.cancel, equals('Cancel'));

      final ta = await AppLocalizations.delegate.load(const Locale('ta'));
      expect(ta.navNotes, equals('குறிப்புகள்'));
      expect(ta.navFinances, equals('நிதி'));
      expect(ta.navTracker, equals('சுழற்சி'));
      expect(ta.settingsTitle, equals('அமைப்புகள்'));
      expect(ta.newNote, equals('புதிய குறிப்பு'));
      expect(ta.newTransaction, equals('புதிய பரிவர்த்தனை'));
      expect(ta.savingsGoals, equals('சேமிப்பு இலக்குகள்'));
      expect(ta.splitBillsTitle, equals('பில் பகிர்வு'));
      expect(ta.save, equals('சேமி'));
      expect(ta.cancel, equals('ரத்து செய்'));

      final zh = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(zh.navNotes, equals('笔记'));
      expect(zh.navFinances, equals('财务'));
      expect(zh.savingsGoals, equals('储蓄目标'));

      final pt = await AppLocalizations.delegate.load(const Locale('pt'));
      expect(pt.navNotes, equals('Notas'));
      expect(pt.navFinances, equals('Finanças'));
      expect(pt.savingsGoals, equals('Metas de Poupança'));

      final es = await AppLocalizations.delegate.load(const Locale('es'));
      expect(es.navNotes, equals('Notas'));
      expect(es.navFinances, equals('Finanzas'));
      expect(es.savingsGoals, equals('Metas de Ahorro'));

      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(fr.navNotes, equals('Notes'));
      expect(fr.navFinances, equals('Finances'));
      expect(fr.savingsGoals, equals('Objectifs d\'Épargne'));

      final de = await AppLocalizations.delegate.load(const Locale('de'));
      expect(de.navNotes, equals('Notizen'));
      expect(de.navFinances, equals('Finanzen'));
      expect(de.savingsGoals, equals('Sparziele'));
    });
  });

  group('Language UI Widget Tests', () {
    testWidgets('MaterialApp dynamically switches between English and Tamil', (WidgetTester tester) async {
      final settings = SettingsProvider();

      await tester.pumpWidget(
        AnimatedBuilder(
          animation: settings,
          builder: (context, _) {
            return MaterialApp(
              locale: settings.currentLocale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Scaffold(
                    body: Column(
                      children: [
                        Text('NOTES_LABEL: ${l10n.navNotes}'),
                        Text('FINANCES_LABEL: ${l10n.navFinances}'),
                        Text('SAVINGS_LABEL: ${l10n.savingsGoals}'),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // By default (system), falls back to English in test environment
      expect(find.text('NOTES_LABEL: Notes'), findsOneWidget);
      expect(find.text('FINANCES_LABEL: Finances'), findsOneWidget);
      expect(find.text('SAVINGS_LABEL: Savings Goals'), findsOneWidget);

      // Switch to Tamil dynamically
      await settings.setSelectedLanguage('ta');
      await tester.pumpAndSettle();

      expect(find.text('NOTES_LABEL: குறிப்புகள்'), findsOneWidget);
      expect(find.text('FINANCES_LABEL: நிதி'), findsOneWidget);
      expect(find.text('SAVINGS_LABEL: சேமிப்பு இலக்குகள்'), findsOneWidget);

      // Switch to Chinese dynamically
      await settings.setSelectedLanguage('zh');
      await tester.pumpAndSettle();

      expect(find.text('NOTES_LABEL: 笔记'), findsOneWidget);
      expect(find.text('FINANCES_LABEL: 财务'), findsOneWidget);
      expect(find.text('SAVINGS_LABEL: 储蓄目标'), findsOneWidget);

      // Switch to Portuguese dynamically
      await settings.setSelectedLanguage('pt');
      await tester.pumpAndSettle();

      expect(find.text('NOTES_LABEL: Notas'), findsOneWidget);
      expect(find.text('FINANCES_LABEL: Finanças'), findsOneWidget);
      expect(find.text('SAVINGS_LABEL: Metas de Poupança'), findsOneWidget);

      // Switch explicitly to English
      await settings.setSelectedLanguage('en');
      await tester.pumpAndSettle();

      expect(find.text('NOTES_LABEL: Notes'), findsOneWidget);
      expect(find.text('FINANCES_LABEL: Finances'), findsOneWidget);
      expect(find.text('SAVINGS_LABEL: Savings Goals'), findsOneWidget);
    });
  });
}
