import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:note_taking_app/data/database_helper.dart';
import 'package:note_taking_app/services/sync_merge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SyncMergeService Non-Destructive Delta Merge Tests', () {
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await DatabaseHelper.instance.createTestDatabase(db);
      DatabaseHelper.setMockDatabase(db);
    });

    tearDown(() async {
      await db.close();
      DatabaseHelper.setMockDatabase(null);
    });

    test('merges remote notes using Last-Write-Wins (LWW) without overwriting local data', () async {
      final now = DateTime.now();
      final olderDate = now.subtract(const Duration(hours: 2)).toIso8601String();
      final newerDate = now.toIso8601String();

      // Seed local database with Note A (edited older) and Note B (unique local)
      await db.insert('notes', {
        'id': 'note_a',
        'title': 'Local Note A Old Title',
        'content': 'Local Content A',
        'dateCreated': olderDate,
        'dateModified': olderDate,
        'color': 0,
        'isPinned': 0,
        'isArchived': 0,
        'category': 'Notes',
      });

      await db.insert('notes', {
        'id': 'note_b',
        'title': 'Unique Local Note B',
        'content': 'Local Content B',
        'dateCreated': olderDate,
        'dateModified': olderDate,
        'color': 0,
        'isPinned': 0,
        'isArchived': 0,
        'category': 'Notes',
      });

      // Prepare remote payload containing Note A (newer edit) and Note C (new remote note)
      final remotePayload = {
        'notes': [
          {
            'id': 'note_a',
            'title': 'Updated Remote Note A Title',
            'content': 'Updated Remote Content A',
            'dateCreated': olderDate,
            'dateModified': newerDate,
            'color': 0,
            'isPinned': 1,
            'isArchived': 0,
            'category': 'Notes',
          },
          {
            'id': 'note_c',
            'title': 'New Remote Note C',
            'content': 'Remote Content C',
            'dateCreated': newerDate,
            'dateModified': newerDate,
            'color': 0,
            'isPinned': 0,
            'isArchived': 0,
            'category': 'Notes',
          },
        ]
      };

      final result = await SyncMergeService.instance.mergeRemoteData(remotePayload);

      expect(result.notesMerged, equals(2));

      // Verify all 3 notes exist in local database
      final allNotes = await db.query('notes', orderBy: 'id ASC');
      expect(allNotes.length, equals(3));

      // Note A should be updated to remote newer version
      final noteA = allNotes.firstWhere((n) => n['id'] == 'note_a');
      expect(noteA['title'], equals('Updated Remote Note A Title'));
      expect(noteA['isPinned'], equals(1));

      // Note B should be untouched (not deleted by sync)
      final noteB = allNotes.firstWhere((n) => n['id'] == 'note_b');
      expect(noteB['title'], equals('Unique Local Note B'));

      // Note C should be inserted
      final noteC = allNotes.firstWhere((n) => n['id'] == 'note_c');
      expect(noteC['title'], equals('New Remote Note C'));
    });

    test('merges remote soft-deleted note (deletedAt) into local Trash correctly', () async {
      final now = DateTime.now();
      final olderDate = now.subtract(const Duration(hours: 2)).toIso8601String();
      final newerDate = now.toIso8601String();

      // Seed local active note
      await db.insert('notes', {
        'id': 'note_del',
        'title': 'Active Note To Be Trashed',
        'content': 'Content',
        'dateCreated': olderDate,
        'dateModified': olderDate,
        'color': 0,
        'isPinned': 0,
        'isArchived': 0,
        'category': 'Notes',
        'deletedAt': null,
      });

      // Prepare remote payload where note_del was soft deleted
      final remotePayload = {
        'notes': [
          {
            'id': 'note_del',
            'title': 'Active Note To Be Trashed',
            'content': 'Content',
            'dateCreated': olderDate,
            'dateModified': newerDate,
            'color': 0,
            'isPinned': 0,
            'isArchived': 0,
            'category': 'Notes',
            'deletedAt': newerDate,
          },
        ]
      };

      final result = await SyncMergeService.instance.mergeRemoteData(remotePayload);

      expect(result.notesMerged, equals(1));

      final note = (await db.query('notes', where: 'id = ?', whereArgs: ['note_del'])).first;
      expect(note['deletedAt'], equals(newerDate));
    });
  });
}
