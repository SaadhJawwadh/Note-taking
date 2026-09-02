import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:uuid/uuid.dart';
import '../../../data/database_helper.dart';
import '../../../data/database_constants.dart';
import '../../../data/note_model.dart';
import '../../../utils/rich_text_utils.dart';
import '../../../screens/app_lock_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../data/note_repository.dart';

class NoteMigrationResult {
  final int totalImported;
  final int skippedCount;
  final List<String> importedTitles;
  final Set<String> importedTags;

  const NoteMigrationResult({
    required this.totalImported,
    required this.skippedCount,
    required this.importedTitles,
    required this.importedTags,
  });
}

class NoteMigrationService {
  static const Map<String, int> _keepColorMap = {
    'DEFAULT': 0xFF252529,
    'RED': 0xFF5C2B29,
    'ORANGE': 0xFF614A19,
    'YELLOW': 0xFF635D19,
    'GREEN': 0xFF345920,
    'TEAL': 0xFF16504B,
    'BLUE': 0xFF2D555E,
    'DARK_BLUE': 0xFF1E3A5F,
    'PURPLE': 0xFF42275E,
    'PINK': 0xFF5B2245,
    'BROWN': 0xFF442F19,
    'GRAY': 0xFF3C3F41,
  };

  /// Pick one or more files (ZIP archive from Google Takeout, JSON, Markdown, or TXT)
  /// and parse them into Note models.
  static Future<List<Note>> pickAndParseNotes() async {
    final result = await AppLockScreen.withLockIgnored(() => FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['json', 'zip', 'md', 'txt'],
    ));

    if (result == null || result.files.isEmpty) return [];

    final parsedNotes = <Note>[];

    for (final file in result.files) {
      if (file.path == null) continue;
      final localFile = File(file.path!);
      if (!await localFile.exists()) continue;

      final ext = file.extension?.toLowerCase() ?? '';

      if (ext == 'zip') {
        final zipNotes = await _parseZipFile(localFile);
        parsedNotes.addAll(zipNotes);
      } else if (ext == 'json') {
        final note = await _parseJsonFile(localFile);
        if (note != null) parsedNotes.add(note);
      } else if (ext == 'md' || ext == 'txt') {
        final note = await _parseMarkdownFile(localFile);
        if (note != null) parsedNotes.add(note);
      }
    }

    return parsedNotes;
  }

  /// Extracts and parses notes from a Google Takeout or backup ZIP file,
  /// including any attached photos or images.
  static Future<List<Note>> _parseZipFile(File file) async {
    final notes = <Note>[];
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final targetDir = await getApplicationDocumentsDirectory();

      // Index all image files in the ZIP archive
      final imageFiles = <String, ArchiveFile>{};
      for (final archiveFile in archive) {
        if (!archiveFile.isFile) continue;
        final name = archiveFile.name.toLowerCase();
        if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png') || name.endsWith('.webp')) {
          final cleanBaseName = archiveFile.name.split('/').last.split('\\').last.toLowerCase();
          imageFiles[cleanBaseName] = archiveFile;
        }
      }

      for (final archiveFile in archive) {
        if (!archiveFile.isFile) continue;
        final name = archiveFile.name.toLowerCase();

        if (name.endsWith('.json') && !name.contains('manifest') && !name.contains('takeout')) {
          try {
            final content = utf8.decode(archiveFile.content as List<int>);
            final note = await _parseKeepJsonString(
              content,
              archiveFile.name,
              imageFiles: imageFiles,
              targetDir: targetDir,
            );
            if (note != null) notes.add(note);
          } catch (_) {}
        } else if (name.endsWith('.md') || name.endsWith('.txt')) {
          try {
            final content = utf8.decode(archiveFile.content as List<int>);
            final note = _parseMarkdownString(content, archiveFile.name);
            if (note != null) notes.add(note);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[NoteMigrationService] Error reading ZIP: $e');
    }
    return notes;
  }

  static Future<Note?> _parseJsonFile(File file) async {
    try {
      final content = await file.readAsString();
      final fileName = file.uri.pathSegments.last;
      return await _parseKeepJsonString(content, fileName);
    } catch (e) {
      debugPrint('[NoteMigrationService] Error parsing JSON file: $e');
      return null;
    }
  }

  static Future<Note?> _parseMarkdownFile(File file) async {
    try {
      final content = await file.readAsString();
      final fileName = file.uri.pathSegments.last;
      final fileStat = await file.stat();
      return _parseMarkdownString(
        content,
        fileName,
        dateCreated: fileStat.changed,
        dateModified: fileStat.modified,
      );
    } catch (e) {
      debugPrint('[NoteMigrationService] Error parsing Markdown file: $e');
      return null;
    }
  }

  /// Parses a Google Keep JSON payload.
  static Future<Note?> _parseKeepJsonString(
    String jsonStr,
    String fallbackFileName, {
    Map<String, ArchiveFile>? imageFiles,
    Directory? targetDir,
  }) async {
    try {
      final data = jsonDecode(jsonStr);
      if (data is! Map<String, dynamic>) return null;

      // Ensure this looks like a Keep note
      final hasText = data.containsKey('textContent');
      final hasList = data.containsKey('listContent');
      final hasTitle = data.containsKey('title');
      if (!hasText && !hasList && !hasTitle) return null;

      String title = (data['title'] as String?)?.trim() ?? '';
      if (title.isEmpty) {
        // Derive title from filename
        title = fallbackFileName.replaceAll(RegExp(r'\.json$', caseSensitive: false), '').replaceAll('_', ' ');
      }

      final tags = <String>[];
      if (data['labels'] is List) {
        for (final label in data['labels']) {
          if (label is Map && label['name'] != null) {
            final tagName = label['name'].toString().trim();
            if (tagName.isNotEmpty && !tags.contains(tagName)) {
              tags.add(tagName);
            }
          }
        }
      }

      // Timestamps (Google Keep uses microseconds since epoch)
      DateTime dateCreated = DateTime.now();
      DateTime dateModified = DateTime.now();
      if (data['createdTimestampUsec'] != null) {
        final usec = int.tryParse(data['createdTimestampUsec'].toString()) ?? 0;
        if (usec > 0) dateCreated = DateTime.fromMicrosecondsSinceEpoch(usec);
      }
      if (data['userEditedTimestampUsec'] != null) {
        final usec = int.tryParse(data['userEditedTimestampUsec'].toString()) ?? 0;
        if (usec > 0) dateModified = DateTime.fromMicrosecondsSinceEpoch(usec);
      }

      final isPinned = data['isPinned'] == true;
      final isArchived = data['isArchived'] == true;

      // Color mapping
      int noteColor = 0xFF252529;
      if (data['color'] != null) {
        final colorKey = data['color'].toString().toUpperCase();
        noteColor = _keepColorMap[colorKey] ?? 0xFF252529;
      }

      // Extract image attachment if present in ZIP archive
      String? savedImagePath;
      if (data['attachments'] is List && imageFiles != null && targetDir != null) {
        for (final att in (data['attachments'] as List)) {
          if (att is Map && att['filePath'] != null) {
            final rawPath = att['filePath'].toString();
            final attName = rawPath.split('/').last.split('\\').last.toLowerCase();
            final matchedFile = imageFiles[attName];
            if (matchedFile != null) {
              final ext = attName.contains('.') ? '.${attName.split('.').last}' : '.jpg';
              final outPath = '${targetDir.path}/keep_att_${const Uuid().v4()}$ext';
              final outFile = File(outPath);
              await outFile.writeAsBytes(matchedFile.content as List<int>);
              savedImagePath = outPath;
              break;
            }
          }
        }
      }

      // Content & Checklist Delta creation
      Delta delta = Delta();

      if (data['listContent'] is List && (data['listContent'] as List).isNotEmpty) {
        // If there's leading text content, insert it first
        final textContent = (data['textContent'] as String?)?.trim() ?? '';
        if (textContent.isNotEmpty) {
          delta.insert('$textContent\n');
        }

        final listItems = data['listContent'] as List;
        for (final item in listItems) {
          if (item is Map) {
            final itemText = (item['text'] as String?)?.trim() ?? '';
            final isChecked = item['isChecked'] == true;
            if (itemText.isNotEmpty) {
              if (isChecked) {
                delta.insert(itemText, {'strike': true});
              } else {
                delta.insert(itemText);
              }
              delta.insert('\n', {'list': isChecked ? 'checked' : 'unchecked'});
            }
          }
        }
      } else {
        // Plain text note
        final textContent = (data['textContent'] as String?) ?? '';
        if (textContent.isNotEmpty) {
          delta = RichTextUtils.markdownToDelta(textContent);
        } else {
          delta.insert('\n');
        }
      }

      final contentJson = RichTextUtils.deltaToJson(delta);

      return Note(
        id: const Uuid().v4(),
        title: title,
        content: contentJson,
        dateCreated: dateCreated,
        dateModified: dateModified,
        color: noteColor,
        isPinned: isPinned,
        isArchived: isArchived,
        tags: tags,
        imagePath: savedImagePath,
      );
    } catch (e) {
      debugPrint('[NoteMigrationService] Keep parse error: $e');
      return null;
    }
  }

  /// Parses Markdown / Plain text note content.
  static Note? _parseMarkdownString(
    String markdownStr,
    String fallbackFileName, {
    DateTime? dateCreated,
    DateTime? dateModified,
  }) {
    if (markdownStr.trim().isEmpty) return null;

    final lines = markdownStr.split('\n');
    String title = '';
    int bodyStartIndex = 0;

    // Check if line 0 is a markdown title '# ...'
    if (lines.isNotEmpty && lines.first.trim().startsWith('# ')) {
      title = lines.first.trim().substring(2).trim();
      bodyStartIndex = 1;
    } else {
      title = fallbackFileName
          .replaceAll(RegExp(r'\.(md|txt)$', caseSensitive: false), '')
          .replaceAll('_', ' ');
    }

    final body = lines.skip(bodyStartIndex).join('\n').trim();
    final delta = RichTextUtils.markdownToDelta(body.isNotEmpty ? body : title);
    final contentJson = RichTextUtils.deltaToJson(delta);

    final tags = <String>[];
    // Extract hashtag labels e.g. #personal, #work
    final tagRegex = RegExp(r'(?:^|\s)#([a-zA-Z0-9_\-]+)');
    for (final match in tagRegex.allMatches(body)) {
      final tag = match.group(1)?.trim();
      if (tag != null && tag.isNotEmpty && !tags.contains(tag)) {
        tags.add(tag);
      }
    }

    return Note(
      id: const Uuid().v4(),
      title: title,
      content: contentJson,
      dateCreated: dateCreated ?? DateTime.now(),
      dateModified: dateModified ?? DateTime.now(),
      color: 0xFF252529,
      tags: tags,
    );
  }

  /// Batch inserts parsed notes and their tags non-destructively into SQLite.
  static Future<NoteMigrationResult> batchInsertNotes(List<Note> notes) async {
    if (notes.isEmpty) {
      return const NoteMigrationResult(
        totalImported: 0,
        skippedCount: 0,
        importedTitles: [],
        importedTags: {},
      );
    }

    final db = await DatabaseHelper.instance.database;
    final importedTitles = <String>[];
    final importedTags = <String>{};
    int importedCount = 0;

    await db.transaction((txn) async {
      for (final note in notes) {
        final enriched = NoteRepository.instance.enrichNoteWithPreview(note);

        await txn.insert(
          TableNames.notes,
          enriched.toMap(),
        );

        for (final tag in enriched.tags) {
          if (tag.trim().isEmpty) continue;
          importedTags.add(tag.trim());
          await txn.insert(
            'tags',
            {'name': tag.trim(), 'color': 0xFF6366F1},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          await txn.insert(
            'note_tags',
            {'note_id': enriched.id, 'tag_name': tag.trim()},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        importedTitles.add(note.title.isNotEmpty ? note.title : 'Untitled');
        importedCount++;
      }
    });

    return NoteMigrationResult(
      totalImported: importedCount,
      skippedCount: notes.length - importedCount,
      importedTitles: importedTitles,
      importedTags: importedTags,
    );
  }
}
