import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/data/settings_provider.dart';
import 'package:note_taking_app/widgets/onboarding_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider Onboarding Tests', () {
    late SettingsProvider settings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settings = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('Default value for hasSeenOnboarding is false', () {
      expect(settings.hasSeenOnboarding, isFalse);
    });

    test('setHasSeenOnboarding updates and persists', () async {
      await settings.setHasSeenOnboarding(true);
      expect(settings.hasSeenOnboarding, isTrue);

      final newSettings = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(newSettings.hasSeenOnboarding, isTrue);
    });
  });

  group('OnboardingSheet Widget Tests', () {
    late SettingsProvider settings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settings = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    Widget buildTestWidget() {
      return ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: const MaterialApp(
          home: Scaffold(
            body: OnboardingSheet(),
          ),
        ),
      );
    }

    testWidgets('Renders onboarding page 1 (Welcome) successfully', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Everything App'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Navigating next pages works', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Page 1 -> Page 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Modular Powerups'), findsOneWidget);

      // Page 2 -> Page 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Where to Find Features'), findsOneWidget);

      // Page 3 -> Page 4
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Quick Pro-Tips'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Skip'), findsNothing); // Skip hidden on last page
    });

    testWidgets('Toggling modules inside onboarding updates settings', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Go to page 2 (Modular Powerups)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(settings.showFinancialManager, isFalse);
      
      // Tap switch for Financial Manager
      final switchFinder = find.byType(Switch).first;
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(settings.showFinancialManager, isTrue);
    });
  });
}
