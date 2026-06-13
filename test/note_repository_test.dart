import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:note_taking_app/data/repositories/note_repository.dart';
import 'package:note_taking_app/data/database_helper.dart';
import 'package:note_taking_app/data/note_model.dart';
import 'package:note_taking_app/data/database_constants.dart';

void main() {
  // Setup sqflite_common_ffi for flutter test
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('NoteRepository clearOldTrash Tests', () {
    late Database db;
    late NoteRepository repository;

    setUp(() async {
      // Open fresh in-memory database
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      
      // Initialize schemas
      await DatabaseHelper.instance.createTestDatabase(db);
      
      // Inject database helper mock
      DatabaseHelper.setMockDatabase(db);
      
      repository = NoteRepository();
    });

    tearDown(() async {
      await db.close();
      DatabaseHelper.setMockDatabase(null);
    });

    test('clearOldTrash purges notes deleted > 7 days ago, but retains recent/active notes', () async {
      final now = DateTime.now();
      
      // 1. Note A: deleted 8 days ago (should be cleared)
      final noteA = Note(
        id: 'note_a_old_trash',
        title: 'Old Trash Note',
        content: 'This note was deleted 8 days ago.',
        dateCreated: now.subtract(const Duration(days: 10)),
        dateModified: now.subtract(const Duration(days: 8)),
        deletedAt: now.subtract(const Duration(days: 8)),
        tags: ['OldTag'],
      );

      // 2. Note B: deleted 3 days ago (should be retained)
      final noteB = Note(
        id: 'note_b_recent_trash',
        title: 'Recent Trash Note',
        content: 'This note was deleted 3 days ago.',
        dateCreated: now.subtract(const Duration(days: 5)),
        dateModified: now.subtract(const Duration(days: 3)),
        deletedAt: now.subtract(const Duration(days: 3)),
        tags: ['RecentTag'],
      );

      // 3. Note C: active note / not deleted (should be retained)
      final noteC = Note(
        id: 'note_c_active',
        title: 'Active Note',
        content: 'This note is not deleted.',
        dateCreated: now.subtract(const Duration(days: 2)),
        dateModified: now,
        deletedAt: null,
        tags: ['ActiveTag'],
      );

      // Insert all notes via repository
      await repository.createNote(noteA);
      await repository.createNote(noteB);
      await repository.createNote(noteC);

      // Verify they are created successfully in the DB
      final initialNotes = await db.query(TableNames.notes);
      expect(initialNotes.length, 3);

      final initialTags = await db.query('note_tags');
      expect(initialTags.length, 3);

      // Call clearOldTrash
      await repository.clearOldTrash();

      // Verify DB contents after purging
      final remainingNotes = await db.query(TableNames.notes);
      expect(remainingNotes.length, 2);

      // Verify which notes remain
      final remainingIds = remainingNotes.map((r) => r[NoteFields.id] as String).toList();
      expect(remainingIds.contains('note_b_recent_trash'), true);
      expect(remainingIds.contains('note_c_active'), true);
      expect(remainingIds.contains('note_a_old_trash'), false);

      // Verify tags are cleaned up properly
      final remainingTags = await db.query('note_tags');
      expect(remainingTags.length, 2);
      final remainingTagNoteIds = remainingTags.map((t) => t['note_id'] as String).toList();
      expect(remainingTagNoteIds.contains('note_b_recent_trash'), true);
      expect(remainingTagNoteIds.contains('note_c_active'), true);
      expect(remainingTagNoteIds.contains('note_a_old_trash'), false);
    });
  });
}
