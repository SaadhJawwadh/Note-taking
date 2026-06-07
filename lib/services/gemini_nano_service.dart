import 'dart:convert';
import 'package:gemini_nano_android/gemini_nano_android.dart';
import 'local_ai_service.dart';

class GeminiNanoService implements LocalAiService {
  final GeminiNanoAndroid _gemini = GeminiNanoAndroid();
  bool? _cachedSupport;

  @override
  Future<bool> isSupported() async {
    if (_cachedSupport != null) return _cachedSupport!;
    try {
      _cachedSupport = await _gemini.isAvailable();
    } catch (_) {
      _cachedSupport = false;
    }
    return _cachedSupport!;
  }

  @override
  Future<String?> generateText(String prompt) async {
    if (!await isSupported()) return null;
    try {
      final results = await _gemini.generate(
        prompt: prompt,
        temperature: 0.3, // Lower temperature for more analytical/accurate responses
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> summarize(String text) async {
    final prompt = """
Summarize the following text concisely using a few bullet points. 
If the text is in Tamil, write the summary in Tamil. Otherwise, write the summary in English.
Keep it clear and readable.

Text:
$text
""";
    return generateText(prompt);
  }

  @override
  Future<List<String>> suggestTags(String noteContent, List<String> existingTags) async {
    final existingTagsList = existingTags.join(', ');
    final prompt = """
You are a tagging assistant. Analyze the note content below and suggest a list of 1 to 3 relevant tags.

Follow these strict tagging rules in order of priority:
1. First, check the list of existing tags: [$existingTagsList]. Match the note's topics against these existing tags. Recommend matching tags from this list.
2. Only suggest a brand new tag if the note discusses a major topic that is NOT covered by any of the existing tags and is highly relevant. Do not generate generic new tags.
3. Respond with ONLY a comma-separated list of suggested tags (all lowercase, no hashtags, no explanations, no formatting). If no tags match or are highly relevant, respond with nothing.

Note content:
$noteContent
""";

    final response = await generateText(prompt);
    if (response == null || response.trim().isEmpty) return [];
    
    final cleanedTags = response
        .split(',')
        .map((tag) => tag.trim().toLowerCase().replaceAll('#', ''))
        .map((tag) => tag.replaceAll(RegExp(r'[^a-z0-9_-]'), ''))
        .where((tag) => tag.length >= 2 && tag != 'all')
        .toList();

    final result = <String>[];
    for (final tag in cleanedTags) {
      final matchedExisting = existingTags.firstWhere(
        (existing) => existing.trim().toLowerCase() == tag,
        orElse: () => '',
      );
      if (matchedExisting.isNotEmpty) {
        result.add(matchedExisting.trim());
      } else {
        result.add(tag);
      }
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>?> parseSmsTransaction(String smsBody, List<String> categories) async {
    final categoriesStr = categories.map((c) => '"$c"').join(', ');
    final prompt = """
Analyze the following bank SMS and extract the transaction details.
Respond with ONLY a raw JSON object with keys:
"amount" (decimal number/float, without currency symbol or commas, e.g., 1500.50),
"merchant" (string, e.g., "Uber Eats" or bank name if transferring),
"category" (string, MUST be exactly one of these values: [$categoriesStr]),
"isExpense" (boolean, true if debited/spent/withdrawn/transferred out, false if credited/received/deposited).

No formatting, no markdown code block (like ```json), no other text. Just the JSON object.

SMS body:
$smsBody
""";

    final response = await generateText(prompt);
    if (response == null || response.trim().isEmpty) return null;
    try {
      // Clean up markdown block format if LLM included it by mistake
      var cleaned = response.trim();
      if (cleaned.startsWith("```json")) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith("```")) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith("```")) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final data = json.decode(cleaned);
      if (data is Map<String, dynamic>) {
        return {
          'amount': data['amount'] != null ? double.tryParse(data['amount'].toString()) : null,
          'merchant': data['merchant']?.toString(),
          'category': data['category']?.toString(),
          'isExpense': data['isExpense'] == true,
        };
      }
    } catch (_) {
      // JSON parsing or structure failure
    }
    return null;
  }
}
