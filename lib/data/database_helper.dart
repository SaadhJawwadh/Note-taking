import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'note_model.dart';
import 'transaction_model.dart';
import 'dart:convert';

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
      version: 6,
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
        tags TEXT,
        deletedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tags (
        name TEXT PRIMARY KEY,
        color INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        isExpense INTEGER NOT NULL,
        category TEXT NOT NULL DEFAULT 'Other',
        smsId TEXT
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_smsId ON transactions(smsId) WHERE smsId IS NOT NULL',
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE notes ADD COLUMN isArchived INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE notes ADD COLUMN deletedAt TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE notes ADD COLUMN tags TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE tags (
          name TEXT PRIMARY KEY,
          color INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE transactions (
          _id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          description TEXT NOT NULL,
          date TEXT NOT NULL,
          isExpense INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute(
        "ALTER TABLE transactions ADD COLUMN category TEXT NOT NULL DEFAULT 'Other'",
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN smsId TEXT',
      );
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_smsId ON transactions(smsId) WHERE smsId IS NOT NULL',
      );
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
        'tags',
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
      where:
          '(title LIKE ? OR content LIKE ? OR tags LIKE ?) AND deletedAt IS NULL',
      whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
      orderBy: 'dateModified DESC',
    );
    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<List<Note>> readArchivedNotes() async {
    final db = await instance.database;
    final result = await db.query('notes',
        where: 'isArchived = 1 AND deletedAt IS NULL',
        orderBy: 'dateModified DESC');
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
    return await db.delete(
      'notes',
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

  /// Moves a note to trash by setting deletedAt to now.
  Future<int> softDeleteNote(String id) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      {'deletedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Restores a trashed note by clearing deletedAt.
  Future<int> restoreNote(String id) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      {'deletedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns all notes in trash (deletedAt IS NOT NULL).
  Future<List<Note>> readTrashedNotes() async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: 'deletedAt IS NOT NULL',
      orderBy: 'deletedAt DESC',
    );
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

  Future<List<String>> getAllTags() async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      columns: ['tags'],
      where: 'deletedAt IS NULL',
    );

    final Set<String> allTags = {};
    for (var row in result) {
      if (row['tags'] != null) {
        try {
          final List<dynamic> tags = jsonDecode(row['tags'] as String);
          allTags.addAll(tags.map((e) => e.toString()));
        } catch (e) {
          // Ignore invalid JSON
        }
      }
    }
    return allTags.toList()..sort();
  }

  Future<Map<String, int>> getAllTagColors() async {
    final db = await instance.database;
    final result = await db.query('tags');
    return {for (var e in result) e['name'] as String: e['color'] as int};
  }

  Future<int?> getTagColor(String tagName) async {
    final db = await instance.database;
    final result = await db.query('tags',
        columns: ['color'], where: 'name = ?', whereArgs: [tagName]);
    if (result.isNotEmpty) {
      return result.first['color'] as int;
    }
    return null;
  }

  Future<void> setTagColor(String tagName, int color) async {
    final db = await instance.database;
    await db.insert(
      'tags',
      {'name': tagName, 'color': color},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> renameTag(String oldTag, String newTag) async {
    final db = await instance.database;
    // Update notes
    final notes = await readAllNotes();
    for (var note in notes) {
      if (note.tags.contains(oldTag)) {
        final updatedTags = List<String>.from(note.tags);
        final index = updatedTags.indexOf(oldTag);
        if (index != -1) {
          updatedTags[index] = newTag;
          updatedTags.sort();
          await updateNote(note.copyWith(tags: updatedTags));
        }
      }
    }

    // Update color entry if exists
    final color = await getTagColor(oldTag);
    if (color != null) {
      await setTagColor(newTag, color);
      await db.delete('tags', where: 'name = ?', whereArgs: [oldTag]);
    }
  }

  Future<void> deleteTag(String tag) async {
    final db = await instance.database;
    // Update notes
    final notes = await readAllNotes();
    for (var note in notes) {
      if (note.tags.contains(tag)) {
        final updatedTags = List<String>.from(note.tags);
        updatedTags.remove(tag);
        await updateNote(note.copyWith(tags: updatedTags));
      }
    }
    // Delete color entry
    await db.delete('tags', where: 'name = ?', whereArgs: [tag]);
  }

  // Transaction CRUD
  Future<TransactionModel> createTransaction(
      TransactionModel transaction) async {
    final db = await instance.database;
    final id = await db.insert('transactions', transaction.toJson());
    return transaction.copy(id: id);
  }

  /// Inserts a transaction that originated from an SMS message.
  /// Uses ConflictAlgorithm.ignore as a safety net against the race condition
  /// where a background isolate and a foreground sync both pass the smsExists
  /// check before either insert completes.
  /// Returns the inserted model (with its new id), or null if the smsId
  /// already exists (duplicate silently ignored).
  Future<TransactionModel?> createSmsTransaction(
      TransactionModel transaction) async {
    final db = await instance.database;
    final id = await db.insert(
      'transactions',
      transaction.toJson(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    if (id <= 0) return null; // smsId UNIQUE constraint fired — already stored
    return transaction.copy(id: id);
  }

  Future<TransactionModel?> readTransaction(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'transactions',
      columns: TransactionFields.values,
      where: '${TransactionFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TransactionModel.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<List<TransactionModel>> readAllTransactions() async {
    final db = await instance.database;
    const orderBy = '${TransactionFields.date} DESC';
    final result = await db.query('transactions', orderBy: orderBy);
    return result.map((json) => TransactionModel.fromJson(json)).toList();
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      transaction.toJson(),
      where: '${TransactionFields.id} = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: '${TransactionFields.id} = ?',
      whereArgs: [id],
    );
  }

  /// Returns true if a transaction with the given [smsId] already exists.
  Future<bool> smsExists(String smsId) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      columns: [TransactionFields.id],
      where: '${TransactionFields.smsId} = ?',
      whereArgs: [smsId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Returns income and expense totals for each of the last [months] calendar months.
  Future<List<Map<String, dynamic>>> getMonthlyTransactionSummary(
      int months) async {
    final db = await instance.database;
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (int i = months - 1; i >= 0; i--) {
      final periodStart = DateTime(now.year, now.month - i, 1);
      final periodEnd = DateTime(now.year, now.month - i + 1, 1);
      final rows = await db.rawQuery('''
        SELECT
          SUM(CASE WHEN isExpense = 0 THEN amount ELSE 0.0 END) AS totalIncome,
          SUM(CASE WHEN isExpense = 1 THEN amount ELSE 0.0 END) AS totalExpense
        FROM transactions
        WHERE date >= ? AND date < ?
      ''', [periodStart.toIso8601String(), periodEnd.toIso8601String()]);
      result.add({
        'month': periodStart,
        'totalIncome':
            (rows.first['totalIncome'] as num?)?.toDouble() ?? 0.0,
        'totalExpense':
            (rows.first['totalExpense'] as num?)?.toDouble() ?? 0.0,
      });
    }
    return result;
  }

  /// Returns all-time total income and expense.
  Future<Map<String, double>> getAllTimeSummary() async {
    final db = await instance.database;
    final rows = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN isExpense = 0 THEN amount ELSE 0.0 END) AS totalIncome,
        SUM(CASE WHEN isExpense = 1 THEN amount ELSE 0.0 END) AS totalExpense
      FROM transactions
    ''');
    return {
      'totalIncome':
          (rows.first['totalIncome'] as num?)?.toDouble() ?? 0.0,
      'totalExpense':
          (rows.first['totalExpense'] as num?)?.toDouble() ?? 0.0,
    };
  }
}
