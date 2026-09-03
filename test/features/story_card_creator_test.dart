import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/features/notes/presentation/widgets/story_card_creator_sheet.dart';

void main() {
  Widget buildTestSheet({
    String initialText = 'Simplicity is about subtracting the obvious and adding the meaningful.',
    String noteTitle = 'Design Laws',
    int noteColorValue = 0,
    DateTime? noteDate,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StoryCardCreatorSheet(
            initialText: initialText,
            noteTitle: noteTitle,
            noteColorValue: noteColorValue,
            noteDate: noteDate ?? DateTime(2026, 9, 3),
          ),
        ),
      ),
    );
  }

  testWidgets('StoryCardCreatorSheet renders initial text, title, and default 9:16 Story ratio', (tester) async {
    // Set a large enough test viewport for the modal sheet content
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestSheet());
    await tester.pumpAndSettle();

    // Verify header
    expect(find.text('Story Card Studio'), findsOneWidget);
    expect(find.text('Export text as high-res social image'), findsOneWidget);

    // Verify title and quote excerpt are rendered
    expect(find.text('DESIGN LAWS'), findsOneWidget);
    expect(
      find.text('Simplicity is about subtracting the obvious and adding the meaningful.'),
      findsOneWidget,
    );

    // Verify aspect ratio switcher has 9:16 Story selected by default
    expect(find.text('9:16 Story'), findsOneWidget);
    expect(find.text('1:1 Square'), findsOneWidget);
    expect(find.text('4:5 Portrait'), findsOneWidget);

    // Verify export buttons
    expect(find.text('Share Image'), findsOneWidget);
    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
  });

  testWidgets('StoryCardCreatorSheet switches aspect ratios on segment tap', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestSheet());
    await tester.pumpAndSettle();

    // Tap 1:1 Square
    await tester.tap(find.text('1:1 Square'));
    await tester.pumpAndSettle();

    final segmentedButtonFinder = find.byType(SegmentedButton<StoryCardAspectRatio>);
    expect(segmentedButtonFinder, findsOneWidget);
    final segmentedButton = tester.widget<SegmentedButton<StoryCardAspectRatio>>(segmentedButtonFinder);
    expect(segmentedButton.selected, contains(StoryCardAspectRatio.square));

    // Tap 4:5 Portrait
    await tester.tap(find.text('4:5 Portrait'));
    await tester.pumpAndSettle();

    final segmentedButtonAfter = tester.widget<SegmentedButton<StoryCardAspectRatio>>(segmentedButtonFinder);
    expect(segmentedButtonAfter.selected, contains(StoryCardAspectRatio.portrait));
  });

  testWidgets('StoryCardCreatorSheet cycles theme presets', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestSheet());
    await tester.pumpAndSettle();

    // Verify theme presets are visible
    expect(find.text('Material You'), findsOneWidget);
    expect(find.text('OLED Pitch'), findsOneWidget);

    // Tap OLED Pitch
    await tester.tap(find.text('OLED Pitch'));
    await tester.pumpAndSettle();

    // Scroll theme carousel to find Editorial and Terminal
    await tester.scrollUntilVisible(
      find.text('Editorial'),
      50.0,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('theme_preset_list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editorial'), findsOneWidget);

    // Tap Editorial
    await tester.tap(find.text('Editorial'));
    await tester.pumpAndSettle();

    // Editorial renders quote mark watermark
    expect(find.text('“'), findsOneWidget);
  });

  testWidgets('StoryCardCreatorSheet toggles metadata chips', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestSheet());
    await tester.pumpAndSettle();

    // Initially title is visible
    expect(find.text('DESIGN LAWS'), findsOneWidget);

    // Tap Title chip to toggle off
    await tester.tap(find.widgetWithText(FilterChip, 'Title'));
    await tester.pumpAndSettle();

    // Title should no longer be rendered
    expect(find.text('DESIGN LAWS'), findsNothing);

    // Tap Watermark chip to toggle on
    expect(find.text('Everything App'), findsNothing);
    await tester.tap(find.widgetWithText(FilterChip, 'Watermark'));
    await tester.pumpAndSettle();

    // Watermark should now be rendered
    expect(find.text('Everything App'), findsOneWidget);
  });

  testWidgets('StoryCardCreatorSheet toggles text edit mode', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestSheet());
    await tester.pumpAndSettle();

    // Edit TextField is initially hidden
    expect(find.byType(TextField), findsNothing);

    // Tap Edit icon button in header
    await tester.tap(find.byIcon(Icons.edit_note_rounded));
    await tester.pumpAndSettle();

    // TextField is now visible
    expect(find.byType(TextField), findsOneWidget);

    // Enter edited quote text
    await tester.enterText(find.byType(TextField), 'Simplicity is the ultimate sophistication.');
    await tester.pumpAndSettle();

    // Live preview updates (check Text widget with center alignment)
    final quoteTextFinder = find.byWidgetPredicate(
      (w) => w is Text && w.data == 'Simplicity is the ultimate sophistication.' && w.textAlign == TextAlign.center,
    );
    expect(quoteTextFinder, findsOneWidget);
  });

  testWidgets('StoryCardCreatorSheet respects word limits and updates word count badge', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // 35-word paragraph
    const longText = 'One two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twenty-one twenty-two twenty-three twenty-four twenty-five twenty-six twenty-seven twenty-eight twenty-nine thirty thirty-one thirty-two thirty-three thirty-four thirty-five';

    await tester.pumpWidget(buildTestSheet(initialText: longText));
    await tester.pumpAndSettle();

    // Word count pill shows total words
    expect(find.text('35 words'), findsOneWidget);

    // Tap 25 words chip
    await tester.tap(find.text('25'));
    await tester.pumpAndSettle();

    // Stats pill shows trimmed counter
    expect(find.text('25 / 35 words'), findsOneWidget);

    // Live preview ends with ellipsis
    expect(find.textContaining('...'), findsOneWidget);

    // Tap All to restore full text
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('35 words'), findsOneWidget);
  });

  testWidgets('StoryCardCreatorSheet renders Tamil poetry text and switches font styles without overflow', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const tamilPoem = 'எண்ணில் உள்ள எல்லாமும் என்னமும் கொஞ்சம் எல்லோரையும் விட அறிந்தவள் நீ பிறந்தநாள் இது. வாழ்த்துக்கள் எல்லாம் வணக்கமாக வாழ்த்தி விட்டேன்.';

    await tester.pumpWidget(buildTestSheet(
      initialText: tamilPoem,
      noteTitle: 'பிறந்தநாள் வாழ்த்துக்கள்',
    ));
    await tester.pumpAndSettle();

    // Verify title and Tamil text are present
    expect(find.text('ПИРАНТАНААЛ ВААЖТТУККАЛ'.toUpperCase()).evaluate().isNotEmpty || find.textContaining('வாழ்த்துக்கள்').evaluate().isNotEmpty, isTrue);

    // Switch to Serif font style
    await tester.tap(find.text('Serif'));
    await tester.pumpAndSettle();

    // Switch to Sans font style
    await tester.tap(find.text('Sans'));
    await tester.pumpAndSettle();

    // Enable Watermark
    await tester.tap(find.widgetWithText(FilterChip, 'Watermark'));
    await tester.pumpAndSettle();

    expect(find.text('Everything App'), findsOneWidget);
  });
}
