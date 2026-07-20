import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';

void main() {
  group('Find in Note Search Logic Unit Tests', () {
    late QuillController quillController;

    setUp(() {
      quillController = QuillController.basic();
      quillController.document.insert(
        0,
        'Flutter is awesome. I love Flutter development with flutter framework.\nFlutter apps run fast.',
      );
    });

    tearDown(() {
      quillController.dispose();
    });

    test('Case-insensitive search finds all occurrences of pattern', () {
      final text = quillController.document.toPlainText();
      const query = 'flutter';
      final matches = RegExp(RegExp.escape(query), caseSensitive: false).allMatches(text);
      final offsets = matches.map((m) => m.start).toList();

      expect(offsets.length, equals(4));
    });

    test('Case-sensitive search finds only exact case occurrences', () {
      final text = quillController.document.toPlainText();
      const query = 'flutter';
      final matches = RegExp(RegExp.escape(query), caseSensitive: true).allMatches(text);
      final offsets = matches.map((m) => m.start).toList();

      expect(offsets.length, equals(1));
    });

    test('Match navigation index wraps correctly in forward and backward directions', () {
      final offsets = [0, 24, 46, 71];
      int currentIndex = 0;

      // Next match (forward)
      currentIndex = (currentIndex + 1) % offsets.length;
      expect(currentIndex, equals(1));

      currentIndex = (currentIndex + 1) % offsets.length;
      expect(currentIndex, equals(2));

      currentIndex = (currentIndex + 1) % offsets.length;
      expect(currentIndex, equals(3));

      currentIndex = (currentIndex + 1) % offsets.length;
      expect(currentIndex, equals(0)); // Wraps back to start

      // Previous match (backward)
      currentIndex = (currentIndex - 1 + offsets.length) % offsets.length;
      expect(currentIndex, equals(3)); // Wraps to end
    });

    test('Empty or no match query produces empty offsets list', () {
      final text = quillController.document.toPlainText();
      const query = 'nonexistent_term_123';
      final matches = RegExp(RegExp.escape(query), caseSensitive: false).allMatches(text);
      final offsets = matches.map((m) => m.start).toList();

      expect(offsets.isEmpty, isTrue);
    });
  });
}
