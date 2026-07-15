import 'package:sqflite_sqlcipher/sqflite.dart';
import '../database_helper.dart';
import '../note_model.dart';
import '../database_constants.dart';
import '../../utils/rich_text_utils.dart';
import '../../services/notification_service.dart';

class NoteRepository {
  static final NoteRepository instance = NoteRepository._init();
  NoteRepository._init();
  factory NoteRepository() => instance;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => await _dbHelper.database;

  Future<void> createNote(Note note) async {
    final enrichedNote = _enrichNoteWithPreview(note);
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert(TableNames.notes, enrichedNote.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('note_tags', where: 'note_id = ?', whereArgs: [enrichedNote.id]);
      for (final tag in enrichedNote.tags) {
        await txn.insert('note_tags', {'note_id': enrichedNote.id, 'tag_name': tag}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<Note?> readNote(String id) async {
    final db = await _db;
    final maps = await db.query(TableNames.notes, where: '${NoteFields.id} = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return await _populateNoteTags(Note.fromMap(maps.first));
  }

  Future<List<Note>> readAllNotes({
    int? limit,
    int? offset,
    String? tag,
    bool isArchived = false,
    bool isTrashed = false,
    String sortMode = 'modified', // modified | created | title | color
    String? folder,
  }) async {
    final db = await _db;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (isTrashed) {
      whereClause = '${NoteFields.deletedAt} IS NOT NULL';
    } else {
      whereClause = '${NoteFields.deletedAt} IS NULL AND ${NoteFields.isArchived} = ?';
      whereArgs.add(isArchived ? 1 : 0);

      if (tag != null && tag != 'All') {
        whereClause += ' AND ${NoteFields.id} IN (SELECT note_id FROM note_tags WHERE tag_name = ?)';
        whereArgs.add(tag);
      }

      if (folder != null) {
        whereClause += ' AND ${NoteFields.category} = ?';
        whereArgs.add(folder);
      }
    }

    final result = await db.query(
      TableNames.notes,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: switch (sortMode) {
        'created' => '${NoteFields.isPinned} DESC, ${NoteFields.dateCreated} DESC',
        'title' => '${NoteFields.isPinned} DESC, LOWER(${NoteFields.title}) ASC',
        'color' => '${NoteFields.isPinned} DESC, ${NoteFields.color} ASC, ${NoteFields.dateModified} DESC',
        _ => '${NoteFields.isPinned} DESC, ${NoteFields.dateModified} DESC',
      },
      limit: limit,
      offset: offset,
    );
    return await _populateNotesTags(result.map((json) => Note.fromMap(json)).toList());
  }

  Future<List<Note>> searchNotes(String keyword) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT * FROM ${TableNames.notes} 
      WHERE (${NoteFields.title} LIKE ? OR ${NoteFields.content} LIKE ? OR 
             ${NoteFields.id} IN (SELECT note_id FROM note_tags WHERE tag_name LIKE ?))
      AND ${NoteFields.deletedAt} IS NULL
      ORDER BY ${NoteFields.dateModified} DESC
    ''', ['%$keyword%', '%$keyword%', '%$keyword%']);
    return await _populateNotesTags(result.map((json) => Note.fromMap(json)).toList());
  }

  Future<int> updateNote(Note note) async {
    final enrichedNote = _enrichNoteWithPreview(note);
    final db = await _db;
    return await db.transaction((txn) async {
      final res = await txn.update(TableNames.notes, enrichedNote.toMap(), where: '${NoteFields.id} = ?', whereArgs: [enrichedNote.id]);
      await txn.delete('note_tags', where: 'note_id = ?', whereArgs: [enrichedNote.id]);
      for (final tag in enrichedNote.tags) {
        await txn.insert('note_tags', {'note_id': enrichedNote.id, 'tag_name': tag}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      return res;
    });
  }

  Future<int> deleteNote(String id) async {
    final db = await _db;
    return await db.transaction((txn) async {
      await txn.delete('note_tags', where: 'note_id = ?', whereArgs: [id]);
      return await txn.delete(TableNames.notes, where: '${NoteFields.id} = ?', whereArgs: [id]);
    });
  }

  Future<int> archiveNote(String id, bool archive) async {
    final db = await _db;
    return await db.update(TableNames.notes, {NoteFields.isArchived: archive ? 1 : 0}, where: '${NoteFields.id} = ?', whereArgs: [id]);
  }

  Future<int> softDeleteNote(String id) async {
    await NotificationService.cancelNoteReminder(id);
    final db = await _db;
    return await db.update(TableNames.notes, {NoteFields.deletedAt: DateTime.now().toIso8601String()}, where: '${NoteFields.id} = ?', whereArgs: [id]);
  }

  Future<int> restoreNote(String id) async {
    final db = await _db;
    return await db.update(TableNames.notes, {NoteFields.deletedAt: null}, where: '${NoteFields.id} = ?', whereArgs: [id]);
  }

  /// Distinct folder names in use by active notes (excluding the default).
  Future<List<String>> getAllFolders() async {
    final db = await _db;
    final rows = await db.rawQuery(
        "SELECT DISTINCT ${NoteFields.category} AS c FROM ${TableNames.notes} "
        "WHERE ${NoteFields.deletedAt} IS NULL AND ${NoteFields.category} IS NOT NULL "
        "AND ${NoteFields.category} != 'All Notes' ORDER BY c COLLATE NOCASE");
    return rows.map((r) => r['c'] as String).toList();
  }

  /// Note count per tag for active (non-archived, non-trashed) notes,
  /// plus an 'All' total, for the filter bar chips.
  Future<Map<String, int>> getTagCounts() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT nt.tag_name AS tag, COUNT(*) AS cnt
      FROM note_tags nt
      JOIN ${TableNames.notes} n ON n.${NoteFields.id} = nt.note_id
      WHERE n.${NoteFields.deletedAt} IS NULL AND n.${NoteFields.isArchived} = 0
      GROUP BY nt.tag_name
    ''');
    final counts = <String, int>{
      for (final r in rows) r['tag'] as String: r['cnt'] as int,
    };
    final total = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM ${TableNames.notes} WHERE ${NoteFields.deletedAt} IS NULL AND ${NoteFields.isArchived} = 0'));
    counts['All'] = total ?? 0;
    return counts;
  }

  Future<Map<String, int>> getFolderCounts() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT ${NoteFields.category} AS folder, COUNT(*) AS cnt
      FROM ${TableNames.notes}
      WHERE ${NoteFields.deletedAt} IS NULL AND ${NoteFields.isArchived} = 0 AND ${NoteFields.category} IS NOT NULL
      GROUP BY ${NoteFields.category}
    ''');
    return <String, int>{
      for (final r in rows) r['folder'] as String: r['cnt'] as int,
    };
  }

  Future<void> bulkSetPinned(List<String> ids, bool pinned) async {
    final db = await _db;
    final batch = db.batch();
    for (final id in ids) {
      batch.update(TableNames.notes, {NoteFields.isPinned: pinned ? 1 : 0},
          where: '${NoteFields.id} = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> bulkArchive(List<String> ids, bool archive) async {
    final db = await _db;
    final batch = db.batch();
    for (final id in ids) {
      batch.update(TableNames.notes, {NoteFields.isArchived: archive ? 1 : 0}, where: '${NoteFields.id} = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> bulkDelete(List<String> ids) async {
    for (final id in ids) {
      await NotificationService.cancelNoteReminder(id);
    }
    final db = await _db;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final id in ids) {
      batch.update(TableNames.notes, {NoteFields.deletedAt: now}, where: '${NoteFields.id} = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> bulkTag(List<String> ids, List<String> tags) async {
    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final id in ids) {
        final currentTagsResult = await txn.query('note_tags', columns: ['tag_name'], where: 'note_id = ?', whereArgs: [id]);
        final currentTags = currentTagsResult.map((r) => r['tag_name'] as String).toSet();
        
        for (final tag in tags) {
          if (!currentTags.contains(tag)) {
            batch.insert('note_tags', {'note_id': id, 'tag_name': tag}, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Note>> readTrashedNotes() async {
    final db = await _db;
    final result = await db.query(TableNames.notes, where: '${NoteFields.deletedAt} IS NOT NULL', orderBy: '${NoteFields.deletedAt} DESC');
    return await _populateNotesTags(result.map((json) => Note.fromMap(json)).toList());
  }

  Future<List<Note>> readNotesByCategory(String category) async {
    final db = await _db;
    final result = await db.query(TableNames.notes, where: '${NoteFields.category} = ? AND ${NoteFields.deletedAt} IS NULL AND ${NoteFields.isArchived} = 0', whereArgs: [category], orderBy: '${NoteFields.dateModified} DESC');
    return await _populateNotesTags(result.map((json) => Note.fromMap(json)).toList());
  }

  Note _enrichNoteWithPreview(Note note) {
    final preview = RichTextUtils.contentToPlainText(note.content, maxLines: 6);
    return note.copyWith(previewText: preview);
  }

  // Tag Operations
  Future<List<String>> getAllTags() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT DISTINCT tag_name FROM note_tags ORDER BY tag_name ASC');
    return result.map((row) => row['tag_name'] as String).toList();
  }

  Future<Map<String, int>> getAllTagColors() async {
    final db = await _db;
    final result = await db.query(TableNames.tags);
    return {for (var e in result) e[TagFields.name] as String: e[TagFields.color] as int};
  }

  Future<int?> getTagColor(String tagName) async {
    final db = await _db;
    final result = await db.query(TableNames.tags, columns: [TagFields.color], where: '${TagFields.name} = ?', whereArgs: [tagName]);
    return result.isNotEmpty ? result.first[TagFields.color] as int : null;
  }

  Future<void> setTagColor(String tagName, int color) async {
    final db = await _db;
    await db.insert(TableNames.tags, {TagFields.name: tagName, TagFields.color: color}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> renameTag(String oldTag, String newTag) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.rawDelete('''
        DELETE FROM note_tags 
        WHERE tag_name = ? 
        AND note_id IN (SELECT note_id FROM note_tags WHERE tag_name = ?)
      ''', [oldTag, newTag]);
      await txn.update('note_tags', {'tag_name': newTag}, where: 'tag_name = ?', whereArgs: [oldTag]);
      final colorRows = await txn.query(TableNames.tags, columns: [TagFields.color], where: '${TagFields.name} = ?', whereArgs: [oldTag]);
      if (colorRows.isNotEmpty) {
        await txn.insert(TableNames.tags, {TagFields.name: newTag, TagFields.color: colorRows.first[TagFields.color] as int}, conflictAlgorithm: ConflictAlgorithm.replace);
        await txn.delete(TableNames.tags, where: '${TagFields.name} = ?', whereArgs: [oldTag]);
      }
    });
  }

  Future<void> deleteTag(String tag) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('note_tags', where: 'tag_name = ?', whereArgs: [tag]);
      await txn.delete(TableNames.tags, where: '${TagFields.name} = ?', whereArgs: [tag]);
    });
  }

  Future<void> clearOldTrash() async {
    final db = await _db;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    await db.transaction((txn) async {
      final oldNotes = await txn.query(
        TableNames.notes,
        columns: [NoteFields.id],
        where: '${NoteFields.deletedAt} IS NOT NULL AND ${NoteFields.deletedAt} < ?',
        whereArgs: [cutoff.toIso8601String()],
      );
      for (final row in oldNotes) {
        final id = row[NoteFields.id] as String;
        await txn.delete('note_tags', where: 'note_id = ?', whereArgs: [id]);
        await txn.delete(TableNames.notes, where: '${NoteFields.id} = ?', whereArgs: [id]);
      }
    });
  }

  Future<Note> _populateNoteTags(Note note) async {
    final db = await _db;
    final result = await db.query('note_tags', where: 'note_id = ?', whereArgs: [note.id]);
    note.tags = result.map((row) => row['tag_name'] as String).toList();
    return note;
  }

  Future<List<Note>> _populateNotesTags(List<Note> notes) async {
    if (notes.isEmpty) return notes;
    final db = await _db;
    final ids = notes.map((n) => "'${n.id}'").join(',');
    final results = await db.rawQuery('SELECT note_id, tag_name FROM note_tags WHERE note_id IN ($ids)');
    final tagMap = <String, List<String>>{};
    for (var row in results) {
      final id = row['note_id'] as String;
      final tag = row['tag_name'] as String;
      tagMap.putIfAbsent(id, () => []).add(tag);
    }
    for (var note in notes) {
      note.tags = tagMap[note.id] ?? [];
    }
    return notes;
  }
}
