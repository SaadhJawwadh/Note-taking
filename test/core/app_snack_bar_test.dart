import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/core/theme/app_layout.dart';
import 'package:note_taking_app/core/ui/app_snack_bar.dart';

void main() {
  testWidgets('AppSnackBar builds floating snackbar with correct icon and text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppSnackBar.showSuccess(context, message: 'Test success message');
                },
                child: const Text('Show SnackBar'),
              );
            },
          ),
        ),
      ),
    );

    // Tap button to trigger SnackBar
    await tester.tap(find.text('Show SnackBar'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 500)); // Finish animation

    // Verify SnackBar contents
    expect(find.text('Test success message'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    final snackBarFinder = find.byType(SnackBar);
    expect(snackBarFinder, findsOneWidget);

    final snackBar = tester.widget<SnackBar>(snackBarFinder);
    expect(snackBar.behavior, equals(SnackBarBehavior.floating));
    expect(snackBar.shape, isA<RoundedRectangleBorder>());
    final shape = snackBar.shape as RoundedRectangleBorder;
    expect(shape.borderRadius, equals(BorderRadius.circular(AppLayout.radiusM)));
  });

  testWidgets('AppSnackBar renders error and info variants correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      AppSnackBar.showError(context, message: 'Error occurred');
                    },
                    child: const Text('Show Error'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppSnackBar.showInfo(context, message: 'Info notice');
                    },
                    child: const Text('Show Info'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Show Error
    await tester.tap(find.text('Show Error'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Error occurred'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

    // Show Info (clears previous)
    await tester.tap(find.text('Show Info'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Info notice'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.text('Error occurred'), findsNothing);
  });
}
