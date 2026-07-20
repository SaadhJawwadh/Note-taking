/// High-performance offline NLP & rule-based engine that acts as a reliable,
/// 100% offline fallback when Android AI Core / Gemini Nano is uninitialized,
/// downloading, or unsupported on the device.
class OfflineAiFallbackService {
  /// Extracts actionable tasks from text and formats them as checkboxes (`☐ Task`).
  static String extractActionItems(String text) {
    if (text.trim().isEmpty) return '';

    final lines = text.split(RegExp(r'\r?\n'));
    final actionItems = <String>[];

    final taskKeywords = RegExp(
      r"^(need to|must|should|todo|task|action|remember to|don't forget to|follow up|prepare|send|email|call|buy|review|check|create|update|complete|finish|schedule|submit|fix|deploy|test)\b",
      caseSensitive: false,
    );

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Remove existing bullet symbols if present
      final cleanLine = trimmed
          .replaceAll(RegExp(r'^[•\-\*\d+\.\s☐☑\[\]]+'), '')
          .trim();
      if (cleanLine.isEmpty) continue;

      // Check if line contains task keywords or action punctuation
      if (taskKeywords.hasMatch(cleanLine) ||
          trimmed.startsWith('☐') ||
          trimmed.startsWith('- [ ]') ||
          trimmed.contains('?') ||
          cleanLine.length > 5) {
        actionItems.add('☐ $cleanLine');
      }
    }

    if (actionItems.isEmpty) {
      // Fallback: convert non-empty sentences to action items
      final sentences = text
          .split(RegExp(r'(?<=[.!?])\s+'))
          .where((s) => s.trim().isNotEmpty)
          .take(5);
      for (var s in sentences) {
        actionItems.add('☐ ${s.trim()}');
      }
    }

    return actionItems.join('\n');
  }

  /// Corrects punctuation, capitalization, double spaces, and common spelling typos.
  static String proofreadAndPolish(String text) {
    if (text.trim().isEmpty) return text;

    var cleaned = text;
    // Fix double spaces
    cleaned = cleaned.replaceAll(RegExp(r' +'), ' ');

    // Capitalize first letter of sentences
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(^|[.!?]\s+)([a-z])'),
      (match) => '${match.group(1)}${match.group(2)!.toUpperCase()}',
    );

    // Common typo fixes
    final typos = {
      r'\bi\b': 'I',
      r'\bdont\b': "don't",
      r'\bcant\b': "can't",
      r'\bwont\b': "won't",
      r'\bisnt\b': "isn't",
      r'\barent\b': "aren't",
      r'\bteh\b': 'the',
      r'\brecieve\b': 'receive',
      r'\bseperate\b': 'separate',
    };

    typos.forEach((pattern, replacement) {
      cleaned = cleaned.replaceAll(RegExp(pattern, caseSensitive: false), replacement);
    });

    // Ensure sentence ends with period if it doesn't end with punctuation
    final trimmed = cleaned.trim();
    if (trimmed.isNotEmpty && !RegExp(r'[.!?:]$').hasMatch(trimmed)) {
      cleaned = '$trimmed.';
    }

    return cleaned;
  }

  /// Condenses text into key summary points.
  static String makeShorter(String text) {
    if (text.trim().isEmpty) return text;

    final sentences = text
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    if (sentences.length <= 2) {
      return text.trim();
    }

    // Take first and last key sentences or top 3 longest key sentences
    sentences.sort((a, b) => b.length.compareTo(a.length));
    final keySentences = sentences.take(3).toList();

    return keySentences.map((s) => '• ${s.trim()}').join('\n');
  }

  /// Expands brief text notes into clear structured paragraphs.
  static String elaborateAndExpand(String text) {
    if (text.trim().isEmpty) return text;

    final lines = text
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();

    final buffer = StringBuffer();
    for (var line in lines) {
      final clean = line.replaceAll(RegExp(r'^[•\-\*\d+\.\s]+'), '').trim();
      if (clean.isEmpty) continue;

      if (buffer.isNotEmpty) buffer.write('\n\n');
      buffer.write('Regarding **$clean**: Ensure detailed review, proper documentation, and align with overall project requirements.');
    }

    return buffer.toString();
  }

  /// Matches note content against active tags list using strict word boundary and semantic keyword rules.
  /// If no existing tags match, auto-detects relevant topic tags (e.g. Movie, Work, Finance).
  static List<String> suggestTags(String noteContent, List<String> existingTags) {
    if (noteContent.trim().isEmpty) return [];

    final contentLower = noteContent.toLowerCase();
    final suggested = <String>[];

    // Semantic dictionary for common tag concepts
    final semanticKeywords = <String, List<String>>{
      'Movie': ['film', 'cinema', 'actor', 'actress', 'director', 'movie', 'show', 'series', 'netflix', 'trailer'],
      'Entertainment': ['movie', 'film', 'music', 'song', 'concert', 'game', 'gaming', 'video', 'show'],
      'Work': ['meeting', 'project', 'deadline', 'client', 'report', 'presentation', 'office', 'sprint', 'task'],
      'Finance': ['budget', 'expense', 'bank', 'payment', 'money', 'cost', 'bill', 'receipt', 'invoice', 'salary'],
      'Health': ['workout', 'exercise', 'gym', 'doctor', 'diet', 'medicine', 'fitness', 'hospital', 'health'],
      'Travel': ['flight', 'hotel', 'trip', 'vacation', 'passport', 'ticket', 'booking', 'tour'],
      'Shopping': ['buy', 'store', 'cart', 'amazon', 'purchase', 'order'],
      'Ideas': ['idea', 'concept', 'brainstorm', 'feature', 'thought'],
    };

    // 1. Try matching against existing tags
    if (existingTags.isNotEmpty) {
      for (var tag in existingTags) {
        final tagTrimmed = tag.trim();
        final tagLower = tagTrimmed.toLowerCase();
        if (tagLower.isEmpty || tagLower == 'all') continue;

        bool isMatch = false;

        if (!tagLower.contains(' ')) {
          final wordRegex = RegExp(r'\b' + RegExp.escape(tagLower) + r'\b');
          if (wordRegex.hasMatch(contentLower)) {
            isMatch = true;
          }
        } else {
          final exactPhraseRegex = RegExp(r'\b' + RegExp.escape(tagLower) + r'\b');
          if (exactPhraseRegex.hasMatch(contentLower)) {
            isMatch = true;
          } else {
            final words = tagLower.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
            if (words.isNotEmpty && words.every((w) => RegExp(r'\b' + RegExp.escape(w) + r'\b').hasMatch(contentLower))) {
              isMatch = true;
            }
          }
        }

        if (!isMatch) {
          final mappedKeywords = semanticKeywords[tagTrimmed] ?? semanticKeywords[tagLower];
          if (mappedKeywords != null) {
            for (var kw in mappedKeywords) {
              if (RegExp(r'\b' + RegExp.escape(kw) + r'\b').hasMatch(contentLower)) {
                isMatch = true;
                break;
              }
            }
          }
        }

        if (isMatch && !suggested.contains(tagTrimmed)) {
          suggested.add(tagTrimmed);
        }
      }
    }

    // 2. If no existing tags matched, fallback to dynamic topic detection
    if (suggested.isEmpty) {
      semanticKeywords.forEach((topicTag, keywords) {
        if (suggested.length >= 3) return;
        for (var kw in keywords) {
          if (RegExp(r'\b' + RegExp.escape(kw) + r'\b').hasMatch(contentLower)) {
            if (!suggested.contains(topicTag)) {
              suggested.add(topicTag);
            }
            break;
          }
        }
      });
    }

    return suggested.take(3).toList();
  }

  /// Generates clean executive summary bullet points.
  static String summarize(String text) {
    if (text.trim().isEmpty) return '';

    final lines = text
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .where((s) => s.trim().length > 10)
        .take(4)
        .toList();

    if (lines.isEmpty) {
      return '• ${text.trim()}';
    }

    return lines.map((l) => '• ${l.trim()}').join('\n');
  }

  /// Fallback bank SMS transaction parser.
  static Map<String, dynamic>? parseSmsTransaction(String smsBody, List<String> categories) {
    if (smsBody.trim().isEmpty) return null;

    final bodyLower = smsBody.toLowerCase();
    final isExpense = bodyLower.contains('debited') ||
        bodyLower.contains('spent') ||
        bodyLower.contains('paid') ||
        bodyLower.contains('withdrawn') ||
        bodyLower.contains('transfer to') ||
        bodyLower.contains('purchase');

    // Amount extraction
    final amountMatch = RegExp(r'(?:LKR|Rs\.?|USD|\$)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false)
        .firstMatch(smsBody) ?? RegExp(r'([\d,]+\.\d{2})').firstMatch(smsBody);

    double amount = 0.0;
    if (amountMatch != null) {
      final amountStr = amountMatch.group(1)?.replaceAll(',', '') ?? '0';
      amount = double.tryParse(amountStr) ?? 0.0;
    }

    if (amount <= 0.0) return null;

    // Description extraction
    String description = 'Transaction';
    if (bodyLower.contains('at ')) {
      final match = RegExp(r'at\s+([A-Za-z0-9\s]+?)(?:\s+on|\s+ref|\.|$)', caseSensitive: false).firstMatch(smsBody);
      if (match != null && match.group(1) != null) {
        description = match.group(1)!.trim();
      }
    } else if (bodyLower.contains('to ')) {
      final match = RegExp(r'to\s+([A-Za-z0-9\s]+?)(?:\s+on|\s+ref|\.|$)', caseSensitive: false).firstMatch(smsBody);
      if (match != null && match.group(1) != null) {
        description = 'Transfer to ${match.group(1)!.trim()}';
      }
    }

    // Category matching
    String selectedCategory = categories.contains('Other') ? 'Other' : (categories.isNotEmpty ? categories.first : 'General');
    for (var cat in categories) {
      if (bodyLower.contains(cat.toLowerCase())) {
        selectedCategory = cat;
        break;
      }
    }

    return {
      'amount': amount,
      'description': description.length > 30 ? description.substring(0, 30) : description,
      'category': selectedCategory,
      'isExpense': isExpense,
    };
  }
}
