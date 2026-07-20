import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/services/gemini_nano_service.dart';
import 'package:note_taking_app/services/offline_ai_fallback_service.dart';

void main() {
  group('OfflineAiFallbackService Unit Tests', () {
    test('extractActionItems converts tasks to checkable items', () {
      const text = 'Need to prepare quarterly report\nRemember to call team at 3 PM\nBuy groceries';
      final result = OfflineAiFallbackService.extractActionItems(text);

      expect(result, contains('☐ Need to prepare quarterly report'));
      expect(result, contains('☐ Remember to call team at 3 PM'));
      expect(result, contains('☐ Buy groceries'));
    });

    test('proofreadAndPolish fixes typos and capitalization', () {
      const text = 'i dont know if teh report is ready';
      final result = OfflineAiFallbackService.proofreadAndPolish(text);

      expect(result, contains('I'));
      expect(result, contains("don't"));
      expect(result, contains('the'));
      expect(result.endsWith('.'), isTrue);
    });

    test('makeShorter condenses multi-sentence text into key points', () {
      const text = 'This is the first long sentence for testing. This is another middle sentence. This is the final concluding sentence.';
      final result = OfflineAiFallbackService.makeShorter(text);

      expect(result, contains('•'));
    });

    test('suggestTags returns matching existing tags', () {
      const text = 'Need to review financial budget and expense reports';
      final existing = ['Finance', 'Work', 'Personal'];

      final suggested = OfflineAiFallbackService.suggestTags(text, existing);
      expect(suggested, contains('Finance'));
    });

    test('suggestTags avoids false prefix matches like Event Summary on "Even a movie"', () {
      const text = 'Even a movie trying to portray a story';
      final existing = ['Event Summary', "Someone Else's", 'Movie'];

      final suggested = OfflineAiFallbackService.suggestTags(text, existing);
      expect(suggested, isNot(contains('Event Summary')));
      expect(suggested, isNot(contains("Someone Else's")));
      expect(suggested, contains('Movie'));
    });

    test('parseSmsTransaction parses bank debits offline', () {
      const sms = 'Your account 1234 has been debited with LKR 2,500.50 at Keells Super on 2026-07-20.';
      final categories = ['Food', 'Bills', 'Shopping', 'Other'];

      final parsed = OfflineAiFallbackService.parseSmsTransaction(sms, categories);
      expect(parsed, isNotNull);
      expect(parsed!['amount'], equals(2500.50));
      expect(parsed['description'], equals('Keells Super'));
      expect(parsed['isExpense'], isTrue);
    });
  });

  group('GeminiNanoService Graceful Fallback Tests', () {
    late GeminiNanoService service;

    setUp(() {
      service = GeminiNanoService();
    });

    test('refineText polish falls back cleanly when AICore is uninitialized', () async {
      const text = 'i cant find teh file';
      final result = await service.refineText(text, 'polish');

      expect(result, isNotNull);
      expect(result!, contains("can't"));
      expect(result, contains("the"));
    });

    test('summarize falls back cleanly when AICore is uninitialized', () async {
      const text = 'Meeting notes: Discussed Q3 budget, hired 2 developers, scheduled release for Friday.';
      final result = await service.summarize(text);

      expect(result, isNotNull);
      expect(result, contains('•'));
    });
  });
}
