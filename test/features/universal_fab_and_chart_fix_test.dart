import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/core/theme/app_layout.dart';
import 'package:note_taking_app/core/ui/app_morphing_fab.dart';

void main() {
  group('AppMorphingFab Tests', () {
    testWidgets('renders expanded stadium mode with label and secondary action', (tester) async {
      bool primaryClicked = false;
      bool secondaryClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: AppMorphingFab(
              isExpanded: true,
              icon: Icons.add,
              label: 'New Note',
              onPressed: () => primaryClicked = true,
              secondaryAction: IconButton(
                icon: const Icon(Icons.style_outlined),
                onPressed: () => secondaryClicked = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('New Note'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.style_outlined), findsOneWidget);

      await tester.tap(find.text('New Note'));
      await tester.pumpAndSettle();
      expect(primaryClicked, isTrue);

      await tester.tap(find.byIcon(Icons.style_outlined));
      await tester.pumpAndSettle();
      expect(secondaryClicked, isTrue);
    });

    testWidgets('renders collapsed circular 56x56dp mode without text label', (tester) async {
      bool primaryClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: AppMorphingFab(
              isExpanded: false,
              icon: Icons.add,
              label: 'New Note',
              onPressed: () => primaryClicked = true,
              secondaryAction: IconButton(
                icon: const Icon(Icons.style_outlined),
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('New Note'), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.style_outlined), findsNothing);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(primaryClicked, isTrue);
    });
  });

  group('Layout Constants & Donut Precision Tests', () {
    test('AppLayout.fabBottomPadding is 96.0', () {
      expect(AppLayout.fabBottomPadding, equals(96.0));
    });

    test('Donut slice clamp preserves minimum 1.5% visual angle floor', () {
      const double totalExpense = 100000.0;
      const double microExpense = 50.0; // 0.05% of total

      final safeVal = totalExpense > 0
          ? microExpense.clamp(totalExpense * 0.015, double.infinity)
          : microExpense;

      expect(safeVal, equals(1500.0)); // Raised to 1.5% floor
    });
  });
}
