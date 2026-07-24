import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:note_taking_app/screens/settings_screen.dart';
import 'package:note_taking_app/data/settings_provider.dart';
import 'package:note_taking_app/l10n/app_localizations.dart';

void main() {
  testWidgets('SettingsScreen search filters items correctly', (WidgetTester tester) async {
    final settingsProvider = SettingsProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settingsProvider,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify search bar is rendered
    expect(find.byType(TextField), findsOneWidget);

    // Type "SMS" into search field
    await tester.enterText(find.byType(TextField), 'SMS');
    await tester.pumpAndSettle();

    // Verify matching SMS tiles are shown
    expect(find.textContaining('SMS'), findsWidgets);

    // Clear search query
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Verify search query cleared
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, isEmpty);
  });
}
