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
1. You MUST ONLY suggest tags that exist in the provided list of existing tags: [$existingTagsList].
2. Do NOT suggest any new tags, custom tags, or tags outside of the provided list under any circumstances. If no existing tags are relevant, suggest nothing.
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
"description" (string, a refined, clean, and professional description of the transaction, max 30 chars. Extract the actual merchant name, utility provider, or peer-to-peer transfer details like "Transfer to [Name]" or "Received from [Name]". For ATM withdrawals, use "ATM Withdrawal"),
"category" (string, MUST be exactly one of these values: [$categoriesStr]. Select the category that best matches the transaction description or purpose),
"isExpense" (boolean, true if debited/spent/withdrawn/transferred out, false if credited/received/deposited).

No formatting, no markdown code block (like ```json), no other text. Just the JSON object.

SMS body:
$smsBody
""";

    final response = await generateText(prompt);
    if (response == null || response.trim().isEmpty) return null;
    try {
      var cleaned = response.trim();
      // Extract the JSON object using brace matching if there's surrounding text or markdown blocks
      final startIndex = cleaned.indexOf('{');
      final endIndex = cleaned.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleaned = cleaned.substring(startIndex, endIndex + 1);
      }

      final data = json.decode(cleaned);
      if (data is Map<String, dynamic>) {
        String matchedCategory = 'Other';
        final parsedCat = data['category']?.toString().trim().toLowerCase();
        if (parsedCat != null) {
          for (final cat in categories) {
            if (cat.trim().toLowerCase() == parsedCat) {
              matchedCategory = cat;
              break;
            }
          }
        }

        final description = data['description']?.toString().trim() ?? data['merchant']?.toString().trim();
        return {
          'amount': data['amount'] != null ? double.tryParse(data['amount'].toString()) : null,
          'merchant': description,
          'description': description,
          'category': matchedCategory,
          'isExpense': data['isExpense'] == true,
        };
      }
    } catch (_) {
      // JSON parsing or structure failure
    }
    return null;
  }

  @override
  Future<String?> refineTransactionDescription(String rawDescription, String smsBody) async {
    final prompt = """
You are a financial assistant. Refine the following transaction description to be short, clean, and professional.
Extract the most relevant merchant name or transaction purpose.
Remove any "Purchase at", "Payment to", account numbers, dates, or technical codes.
If it's a peer-to-peer transfer, use "Transfer to [Name]" or "Received from [Name]".
If it's an ATM withdrawal, use "ATM Withdrawal".

Raw Description: $rawDescription
Original SMS: $smsBody

Respond with ONLY the refined description (max 30 characters). No punctuation at the end.
""";
    final result = await generateText(prompt);
    if (result == null) return null;
    
    // Clean up any extra noise the LLM might have added
    var cleaned = result.trim();
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    return cleaned.length > 35 ? cleaned.substring(0, 35) : cleaned;
  }

  @override
  Future<String?> refineText(String text, String mode) async {
    String instruction;
    switch (mode.toLowerCase()) {
      case 'polish':
        instruction = "Correct any grammar, spelling, punctuation, and style issues in the text. Respond with ONLY the corrected text, with no explanations, introduction, or quotes.";
        break;
      case 'shorten':
        instruction = "Summarize or shorten the text to make it extremely concise and direct while preserving all essential information. Respond with ONLY the shortened version.";
        break;
      case 'expand':
        instruction = "Elaborate and expand the text, adding helpful details, descriptions, or professional formatting. Respond with ONLY the expanded version.";
        break;
      case 'professional':
        instruction = "Rewrite the text in a formal, professional, and business-ready tone. Respond with ONLY the rewritten text.";
        break;
      case 'casual':
        instruction = "Rewrite the text in a friendly, approachable, and casual tone. Respond with ONLY the rewritten text.";
        break;
      default:
        instruction = "Refine the text based on standard editing rules. Respond with ONLY the refined version.";
    }

    final prompt = """
$instruction

Text to process:
$text
""";
    return generateText(prompt);
  }
}
