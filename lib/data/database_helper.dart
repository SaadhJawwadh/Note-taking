import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'note_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        dateCreated TEXT NOT NULL,
        dateModified TEXT NOT NULL,
        color INTEGER NOT NULL,
        isPinned INTEGER NOT NULL,
        isArchived INTEGER NOT NULL DEFAULT 0,
        imagePath TEXT,
        category TEXT,
        deletedAt TEXT
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE notes ADD COLUMN isArchived INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE notes ADD COLUMN deletedAt TEXT');
    }
  }

  Future<void> createNote(Note note) async {
    final db = await instance.database;
    await db.insert('notes', note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Note?> readNote(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'notes',
      columns: [
        'id',
        'title',
        'content',
        'dateCreated',
        'dateModified',
        'color',
        'isPinned',
        'isArchived',
        'imagePath',
        'category',
        'deletedAt'
      ],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Note>> readAllNotes() async {
    final db = await instance.database;
    final result = await db.query('notes',
        where: 'deletedAt IS NULL',
        orderBy: 'isPinned DESC, dateModified DESC');

    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<List<Note>> searchNotes(String keyword) async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: '(title LIKE ? OR content LIKE ?) AND deletedAt IS NULL',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'dateModified DESC',
    );
    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(String id) async {
    final db = await instance.database;
    // Soft delete: set deletedAt
    return await db.update(
      'notes',
      {'deletedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> archiveNote(String id, bool archive) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      {'isArchived': archive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> restoreNote(String id) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      {'deletedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> hardDeleteNote(String id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> readArchivedNotes() async {
    final db = await instance.database;
    final result = await db.query('notes',
        where: 'isArchived = 1 AND deletedAt IS NULL',
        orderBy: 'dateModified DESC');
    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<List<Note>> readTrashedNotes() async {
    final db = await instance.database;
    final result = await db.query('notes',
        where: 'deletedAt IS NOT NULL', orderBy: 'dateModified DESC');
    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<List<Note>> readNotesByCategory(String category) async {
    final db = await instance.database;
    final result = await db.query('notes',
        where: 'category = ? AND deletedAt IS NULL AND isArchived = 0',
        whereArgs: [category],
        orderBy: 'dateModified DESC');
    return result.map((json) => Note.fromMap(json)).toList();
  }
}
