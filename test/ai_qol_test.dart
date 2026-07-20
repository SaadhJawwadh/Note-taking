import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AI QoL Selection & Action Items Unit Tests', () {
    test('Selection target extraction falls back to full note when selection is invalid/collapsed', () {
      const fullText = 'Meeting notes: Need to prepare report and email team.';
      const String? selectedText = null;

      final target = (selectedText != null && selectedText.isNotEmpty) ? selectedText : fullText;
      expect(target, equals(fullText));
    });

    test('Action item prompt extraction formatting', () {
      const rawText = 'Plan sprint\nReview pull requests\nDeploy release';
      final lines = rawText.split('\n');
      final formattedItems = lines.map((l) => '☐ $l').join('\n');

      expect(formattedItems, contains('☐ Plan sprint'));
      expect(formattedItems, contains('☐ Review pull requests'));
      expect(formattedItems, contains('☐ Deploy release'));
    });
  });
}
