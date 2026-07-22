import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/services/gemini_nano_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('gemini_nano_android');
  late GeminiNanoService service;
  String? mockResponse;

  setUp(() {
    service = GeminiNanoService();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'isAvailable') {
        return true;
      }
      if (methodCall.method == 'generateText') {
        return <String>[mockResponse ?? ''];
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    mockResponse = null;
  });

  group('GeminiNanoService - Support and Generation', () {
    test('isSupported returns true when available', () async {
      final supported = await service.isSupported();
      expect(supported, isTrue);
    });

    test('generateText returns string response', () async {
      mockResponse = 'Hello from AI';
      final response = await service.generateText('Say hello');
      expect(response, 'Hello from AI');
    });

    test('summarize returns summary prompt result', () async {
      mockResponse = '• Bullet point 1\n• Bullet point 2';
      final summary = await service.summarize('Long content here');
      expect(summary, contains('Bullet point 1'));
    });
  });

  group('GeminiNanoService - JSON Guardrails and SMS parsing', () {
    final categories = ['Food', 'Transport', 'Utilities', 'Salary', 'Other'];

    test('parseSmsTransaction parses clean JSON', () async {
      mockResponse = '{"amount": 150.50, "merchant": "Uber Eats", "category": "Food", "isExpense": true}';
      final result = await service.parseSmsTransaction('SMS Body', categories);
      expect(result, isNotNull);
      expect(result!['amount'], 150.50);
      expect(result['merchant'], 'Uber Eats');
      expect(result['category'], 'Food');
      expect(result['isExpense'], isTrue);
    });

    test('parseSmsTransaction parses JSON wrapped in markdown code blocks', () async {
      mockResponse = '```json\n{"amount": 25.00, "merchant": "PickMe", "category": "Transport", "isExpense": true}\n```';
      final result = await service.parseSmsTransaction('SMS Body', categories);
      expect(result, isNotNull);
      expect(result!['amount'], 25.00);
      expect(result['merchant'], 'PickMe');
      expect(result['category'], 'Transport');
      expect(result['isExpense'], isTrue);
    });

    test('parseSmsTransaction parses JSON with noisy text prefix/suffix and case-insensitive matching', () async {
      mockResponse = 'Here is the extracted transaction details:\n{"amount": "95000", "merchant": "Company", "category": "salary", "isExpense": false}\nHope this helps!';
      final result = await service.parseSmsTransaction('SMS Body', categories);
      expect(result, isNotNull);
      expect(result!['amount'], 95000.0);
      expect(result['merchant'], 'Company');
      expect(result['category'], 'Salary'); // case matched
      expect(result['isExpense'], isFalse);
    });

    test('parseSmsTransaction returns other when category is unmatched', () async {
      mockResponse = '{"amount": 5.00, "merchant": "Vendor", "category": "unmatched_category", "isExpense": true}';
      final result = await service.parseSmsTransaction('SMS Body', categories);
      expect(result, isNotNull);
      expect(result!['category'], 'Other');
    });

    test('parseSmsTransaction correctly parses ComBank Digital-Transfer as expense', () async {
      mockResponse = '{"amount": 1727.00, "merchant": "ComBank Digital-Transfer", "category": "Other", "isExpense": true}';
      final result = await service.parseSmsTransaction('ComBank Digital-Transfer within ComBank LKR 1,727.00 attempted.', categories);
      expect(result, isNotNull);
      expect(result!['amount'], 1727.00);
      expect(result['isExpense'], isTrue);
    });

    test('parseSmsTransaction returns null on invalid JSON', () async {
      mockResponse = 'This is not JSON at all { invalid }';
      final result = await service.parseSmsTransaction('SMS Body', categories);
      expect(result, isNull);
    });
  });

  group('GeminiNanoService - Tag Suggestions', () {
    test('suggestTags returns only existing tags, discarding new ones', () async {
      mockResponse = 'work, projects, important';
      final tags = await service.suggestTags('Some note content about projects', ['work', 'important']);
      expect(tags, containsAll(['work', 'important']));
      expect(tags, isNot(contains('projects')));
    });
  });

  group('GeminiNanoService - Text Refiners', () {
    test('refineText polish mode', () async {
      mockResponse = 'Polished text';
      final result = await service.refineText('raw text', 'polish');
      expect(result, 'Polished text');
    });

    test('refineText shorten mode', () async {
      mockResponse = 'Short text';
      final result = await service.refineText('raw text', 'shorten');
      expect(result, 'Short text');
    });

    test('refineText expand mode', () async {
      mockResponse = 'Expanded text';
      final result = await service.refineText('raw text', 'expand');
      expect(result, 'Expanded text');
    });

    test('refineText professional mode', () async {
      mockResponse = 'Professional text';
      final result = await service.refineText('raw text', 'professional');
      expect(result, 'Professional text');
    });

    test('refineText casual mode', () async {
      mockResponse = 'Casual text';
      final result = await service.refineText('raw text', 'casual');
      expect(result, 'Casual text');
    });
  });
}
