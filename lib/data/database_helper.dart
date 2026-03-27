import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:math';
import 'period_log_model.dart';
import 'note_model.dart';
import 'transaction_model.dart';
import 'category_definition.dart';
import 'sms_contact.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_constants.dart';
import 'database_seed.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static Future<Database>? _databaseFuture;

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _keyStorageKey = 'db_encryption_key';

  DatabaseHelper._init();

  Future<Database> get database {
    if (_database != null) return Future.value(_database!);
    
    // Prevent concurrent initialization calls which can corrupt SQLCipher
    _databaseFuture ??= _initDB('notes.db').then((db) {
      _database = db;
      return db;
    }).catchError((error) {
      _databaseFuture = null; // Reset on failure so we can try again
      throw error;
    });
    
    return _databaseFuture!;
  }

  static Future<String> _getOrCreateEncryptionKey() async {
    String? key;
    try {
      key = await _secureStorage.read(key: _keyStorageKey);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    
    if (key == null || key.isEmpty) {
      key = prefs.getString('db_encryption_key_backup');
      if (key != null && key.isNotEmpty) {
        try {
          await _secureStorage.write(key: _keyStorageKey, value: key);
        } catch (_) {}
      }
    }

    if (key == null || key.isEmpty) {
      final random = Random.secure();
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      key = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      
      try {
        await _secureStorage.write(key: _keyStorageKey, value: key);
      } catch (_) {}
      await prefs.setString('db_encryption_key_backup', key);
    } else {
      final existingFallback = prefs.getString('db_encryption_key_backup');
      if (existingFallback != key) {
        await prefs.setString('db_encryption_key_backup', key);
      }
    }
    return key;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    final password = await _getOrCreateEncryptionKey();

    final dbFile = File(path);
    if (await dbFile.exists()) {
      if (await _isUnencryptedDb(path)) {
        await _migrateToEncrypted(path, password);
      }
    }

    try {
      return await openDatabase(
        path,
        password: password,
        version: 13,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    } catch (e) {
      // If the database file is corrupted (e.g., Code 26 from a previous bad
      // concurrent init), delete it and create a fresh one. This is a
      // last-resort self-healing measure.
      if (e.toString().contains('open_failed') || e.toString().contains('26')) {
        debugPrint('DatabaseHelper: Corrupt database detected, resetting...');
        try {
          if (await dbFile.exists()) await dbFile.delete();
          // Also delete WAL and SHM files if they exist
          final walFile = File('$path-wal');
          final shmFile = File('$path-shm');
          if (await walFile.exists()) await walFile.delete();
          if (await shmFile.exists()) await shmFile.delete();
        } catch (deleteError) {
          debugPrint('DatabaseHelper: Could not delete corrupt file: $deleteError');
        }
        // Retry once with a fresh database
        return await openDatabase(
          path,
          password: password,
          version: 13,
          onCreate: _createDB,
          onUpgrade: _upgradeDB,
        );
      }
      rethrow;
    }
  }


  static Future<bool> _isUnencryptedDb(String path) async {
    Database? db;
    try {
      db = await openDatabase(path, readOnly: true, singleInstance: false);
      await db.rawQuery('SELECT count(*) FROM sqlite_master');
      return true;
    } catch (_) {
      return false;
    } finally {
      await db?.close();
    }
  }

  static Future<void> _migrateToEncrypted(String path, String password) async {
    final encryptedPath = '$path.encrypted';
    try {
      final oldDb = await openDatabase(path, singleInstance: false);
      final versionResult = await oldDb.rawQuery("PRAGMA user_version");
      final userVersion = versionResult.first.values.first as int;

      await oldDb.execute("ATTACH DATABASE '$encryptedPath' AS encrypted KEY '$password'");
      await oldDb.rawQuery("SELECT sqlcipher_export('encrypted')");
      await oldDb.execute("PRAGMA encrypted.user_version = $userVersion");
      await oldDb.execute("DETACH DATABASE encrypted");
      await oldDb.close();

      final oldFile = File(path);
      final encFile = File(encryptedPath);
      if (await oldFile.exists()) await oldFile.delete();
      await encFile.rename(path);
    } catch (e) {
      final encFile = File(encryptedPath);
      if (await encFile.exists()) await encFile.delete();
      rethrow;
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${TableNames.notes} (
        ${NoteFields.id} TEXT PRIMARY KEY,
        ${NoteFields.title} TEXT NOT NULL,
        ${NoteFields.content} TEXT NOT NULL,
        ${NoteFields.dateCreated} TEXT NOT NULL,
        ${NoteFields.dateModified} TEXT NOT NULL,
        ${NoteFields.color} INTEGER NOT NULL,
        ${NoteFields.isPinned} INTEGER NOT NULL,
        ${NoteFields.isArchived} INTEGER NOT NULL DEFAULT 0,
        ${NoteFields.imagePath} TEXT,
        ${NoteFields.category} TEXT,
        ${NoteFields.tags} TEXT,
        ${NoteFields.deletedAt} TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${TableNames.tags} (
        ${TagFields.name} TEXT PRIMARY KEY,
        ${TagFields.color} INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS note_tags (
        note_id TEXT NOT NULL,
        tag_name TEXT NOT NULL,
        PRIMARY KEY (note_id, tag_name),
        FOREIGN KEY (note_id) REFERENCES ${TableNames.notes} (${NoteFields.id}) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${TableNames.transactions} (
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
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_smsId ON ${TableNames.transactions}(smsId) WHERE smsId IS NOT NULL',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${TableNames.categoryDefinitions} (
        ${CategoryFields.name} TEXT PRIMARY KEY,
        ${CategoryFields.color} INTEGER NOT NULL,
        ${CategoryFields.keywords} TEXT NOT NULL DEFAULT '[]',
        ${CategoryFields.isBuiltIn} INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await DatabaseSeed.seedBuiltInCategories(db);

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${TableNames.smsContacts} (
        ${SmsContactFields.id} TEXT PRIMARY KEY,
        ${SmsContactFields.senderIds} TEXT NOT NULL DEFAULT '[]',
        ${SmsContactFields.label} TEXT,
        ${SmsContactFields.isBuiltIn} INTEGER NOT NULL DEFAULT 0,
        ${SmsContactFields.isBlocked} INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await DatabaseSeed.seedBuiltInSmsContacts(db);

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${TableNames.periodLogs} (
        ${PeriodLogFields.id} TEXT PRIMARY KEY,
        ${PeriodLogFields.startDate} TEXT NOT NULL,
        ${PeriodLogFields.endDate} TEXT,
        ${PeriodLogFields.intensity} TEXT NOT NULL,
        ${PeriodLogFields.notes} TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ${TableNames.notes} ADD COLUMN ${NoteFields.isArchived} INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE ${TableNames.notes} ADD COLUMN ${NoteFields.deletedAt} TEXT');
    }
    if (oldVersion < 3) await db.execute('ALTER TABLE ${TableNames.notes} ADD COLUMN ${NoteFields.tags} TEXT');
    if (oldVersion < 4) await db.execute('CREATE TABLE IF NOT EXISTS ${TableNames.tags} (${TagFields.name} TEXT PRIMARY KEY, ${TagFields.color} INTEGER NOT NULL)');
    if (oldVersion < 5) await db.execute('CREATE TABLE IF NOT EXISTS ${TableNames.transactions} (_id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL, description TEXT NOT NULL, date TEXT NOT NULL, isExpense INTEGER NOT NULL)');
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE ${TableNames.transactions} ADD COLUMN category TEXT NOT NULL DEFAULT 'Other'");
      await db.execute('ALTER TABLE ${TableNames.transactions} ADD COLUMN smsId TEXT');
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_smsId ON ${TableNames.transactions}(smsId) WHERE smsId IS NOT NULL');
    }
    if (oldVersion < 7) {
      await db.execute('CREATE TABLE IF NOT EXISTS ${TableNames.categoryDefinitions} (${CategoryFields.name} TEXT PRIMARY KEY, ${CategoryFields.color} INTEGER NOT NULL, ${CategoryFields.keywords} TEXT NOT NULL DEFAULT "[]", ${CategoryFields.isBuiltIn} INTEGER NOT NULL DEFAULT 0)');
      await DatabaseSeed.seedBuiltInCategories(db);
    }
    if (oldVersion < 8) {
      final newCats = [
        ('Payments', 0xFF795548, ['koko instalment', 'koko installment', 'instalment', 'installment', 'emi', 'koko', 'loan', 'repayment', 'credit card', 'card payment', 'hire purchase']),
        ('Deposit', 0xFF00897B, ['crm deposit', 'cash deposit', 'deposit', 'credited', 'salary', 'income']),
      ];
      for (final (name, color, kws) in newCats) {
        await db.insert(TableNames.categoryDefinitions, {CategoryFields.name: name, CategoryFields.color: color, CategoryFields.keywords: jsonEncode(kws), CategoryFields.isBuiltIn: 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
    if (oldVersion < 9) await db.execute('CREATE TABLE IF NOT EXISTS sms_whitelist (sender TEXT PRIMARY KEY)');
    if (oldVersion < 10) {
      await db.execute('CREATE TABLE IF NOT EXISTS ${TableNames.smsContacts} (${SmsContactFields.id} TEXT PRIMARY KEY, ${SmsContactFields.senderIds} TEXT NOT NULL DEFAULT "[]", ${SmsContactFields.label} TEXT, ${SmsContactFields.isBuiltIn} INTEGER NOT NULL DEFAULT 0, ${SmsContactFields.isBlocked} INTEGER NOT NULL DEFAULT 0)');
      await DatabaseSeed.seedBuiltInSmsContacts(db);
      final hasOld = (await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='sms_whitelist'")).isNotEmpty;
      if (hasOld) {
        final oldRows = await db.query('sms_whitelist');
        for (final row in oldRows) {
          final sender = row['sender'] as String;
          await db.insert(TableNames.smsContacts, {SmsContactFields.id: sender, SmsContactFields.senderIds: jsonEncode([sender]), SmsContactFields.label: null, SmsContactFields.isBuiltIn: 0, SmsContactFields.isBlocked: 0}, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await db.execute('DROP TABLE sms_whitelist');
      }
    }
    if (oldVersion < 11) await db.execute('CREATE TABLE IF NOT EXISTS ${TableNames.periodLogs} (${PeriodLogFields.id} TEXT PRIMARY KEY, ${PeriodLogFields.startDate} TEXT NOT NULL, ${PeriodLogFields.endDate} TEXT, ${PeriodLogFields.intensity} TEXT NOT NULL, ${PeriodLogFields.notes} TEXT NOT NULL DEFAULT "")');
    if (oldVersion < 12) {
      await db.execute('ALTER TABLE ${TableNames.periodLogs} RENAME TO period_logs_old');
      await db.execute('CREATE TABLE ${TableNames.periodLogs} (${PeriodLogFields.id} TEXT PRIMARY KEY, ${PeriodLogFields.startDate} TEXT NOT NULL, ${PeriodLogFields.endDate} TEXT, ${PeriodLogFields.intensity} TEXT NOT NULL, ${PeriodLogFields.notes} TEXT NOT NULL DEFAULT "")');
      await db.execute('INSERT INTO ${TableNames.periodLogs} (${PeriodLogFields.id}, ${PeriodLogFields.startDate}, ${PeriodLogFields.endDate}, ${PeriodLogFields.intensity}, ${PeriodLogFields.notes}) SELECT ${PeriodLogFields.id}, ${PeriodLogFields.startDate}, NULLIF(${PeriodLogFields.endDate}, ""), ${PeriodLogFields.intensity}, ${PeriodLogFields.notes} FROM period_logs_old');
      await db.execute('DROP TABLE period_logs_old');
    }
    if (oldVersion < 13) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS note_tags (
          note_id TEXT NOT NULL,
          tag_name TEXT NOT NULL,
          PRIMARY KEY (note_id, tag_name),
          FOREIGN KEY (note_id) REFERENCES ${TableNames.notes} (${NoteFields.id}) ON DELETE CASCADE
        )
      ''');
      // Populate note_tags from existing notes
      final notes = await db.query(TableNames.notes, columns: [NoteFields.id, NoteFields.tags]);
      for (final note in notes) {
        final id = note[NoteFields.id] as String;
        final tagsJson = note[NoteFields.tags] as String?;
        if (tagsJson != null) {
          try {
            final List<dynamic> tags = jsonDecode(tagsJson);
            for (final tag in tags) {
              await db.insert('note_tags', {'note_id': id, 'tag_name': tag.toString()}, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
          } catch (_) {}
        }
      }
    }
  }

  Future<Note> _populateNoteTags(Note note) async {
    final db = await instance.database;
    final result = await db.query('note_tags', where: 'note_id = ?', whereArgs: [note.id]);
    note.tags = result.map((row) => row['tag_name'] as String).toList();
    return note;
  }

  Future<List<Note>> _populateNotesTags(List<Note> notes) async {
    if (notes.isEmpty) return notes;
    final db = await instance.database;
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

  // Note CRUD
  Future<void> createNote(Note note) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert(TableNames.notes, note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('note_tags', where: 'note_id = ?', whereArgs: [note.id]);
      for (final tag in note.tags) {
        await txn.insert('note_tags', {'note_id': note.id, 'tag_name': tag}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<Note?> readNote(String id) async {
    final db = await instance.database;
    final maps = await db.query(TableNames.notes, where: '${NoteFields.id} = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return await _populateNoteTags(Note.fromMap(maps.first));
  }

  Future<List<Note>> readAllNotes({int? limit, int? offset}) async {
    final db = await instance.database;
    final result = await db.query(TableNames.notes, where: '${NoteFields.deletedAt} IS NULL', orderBy: '${NoteFields.isPinned} DESC, ${NoteFields.dateModified} DESC', limit: limit, offset: offset);
    return await _populateNotesTags(result.map((json) => Note.fromMap(json)).toList());
  }

  Future<List<Note>> searchNotes(String keyword) async {
    final db = await instance.database;
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
    final db = await instance.database;
    return await db.transaction((txn) async {
      final res = await txn.update(TableNames.notes, note.toMap(), where: '${NoteFields.id} = ?', whereArgs: [note.id]);
      await txn.delete('note_tags', where: 'note_id = ?', whereArgs: [note.id]);
      for (final tag in note.tags) {
        await txn.insert('note_tags', {'note_id': note.id, 'tag_name': tag}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      return res;
    });
  }

  Future<int> deleteNote(String id) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      await txn.delete('note_tags', where: 'note_id = ?', whereArgs: [id]);
      return await txn.delete(TableNames.notes, where: '${NoteFields.id} = ?', whereArgs: [id]);
    });
  }

  Future<int> archiveNote(String id, bool archive) async {
    final db = await instance.database;
    return await db.update(TableNames.notes, {NoteFields.isArchived: archive ? 1 : 0}, where: '${NoteFields.id} = ?', whereArgs: [id]);
  }

  Future<int> softDeleteNote(String id) async {
    final db = await instance.database;
    return await db.update(TableNames.notes, {NoteFields.deletedAt: DateTime.now().toIso8601String()}, where: '${NoteFields.id} = ?', whereArgs: [id]);
  }

  Future<int> restoreNote(String id) async {
    final db = await instance.database;
    return await db.update(TableNames.notes, {NoteFields.deletedAt: null}, where: '${NoteFields.id} = ?', whereArgs: [id]);
  }

  Future<List<Note>> readTrashedNotes() async {
    final db = await instance.database;
    final result = await db.query(TableNames.notes, where: '${NoteFields.deletedAt} IS NOT NULL', orderBy: '${NoteFields.deletedAt} DESC');
    return await _populateNotesTags(result.map((json) => Note.fromMap(json)).toList());
  }

  Future<List<Note>> readNotesByCategory(String category) async {
    final db = await instance.database;
    final result = await db.query(TableNames.notes, where: '${NoteFields.category} = ? AND ${NoteFields.deletedAt} IS NULL AND ${NoteFields.isArchived} = 0', whereArgs: [category], orderBy: '${NoteFields.dateModified} DESC');
    return await _populateNotesTags(result.map((json) => Note.fromMap(json)).toList());
  }

  // Tag Operations
  Future<List<String>> getAllTags() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT DISTINCT tag_name FROM note_tags ORDER BY tag_name ASC');
    return result.map((row) => row['tag_name'] as String).toList();
  }

  Future<Map<String, int>> getAllTagColors() async {
    final db = await instance.database;
    final result = await db.query(TableNames.tags);
    return {for (var e in result) e[TagFields.name] as String: e[TagFields.color] as int};
  }

  Future<int?> getTagColor(String tagName) async {
    final db = await instance.database;
    final result = await db.query(TableNames.tags, columns: [TagFields.color], where: '${TagFields.name} = ?', whereArgs: [tagName]);
    return result.isNotEmpty ? result.first[TagFields.color] as int : null;
  }

  Future<void> setTagColor(String tagName, int color) async {
    final db = await instance.database;
    await db.insert(TableNames.tags, {TagFields.name: tagName, TagFields.color: color}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> renameTag(String oldTag, String newTag) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // 1. Delete oldTag for notes that already have newTag to avoid PK conflict
      await txn.rawDelete('''
        DELETE FROM note_tags 
        WHERE tag_name = ? 
        AND note_id IN (SELECT note_id FROM note_tags WHERE tag_name = ?)
      ''', [oldTag, newTag]);

      // 2. Rename remaining oldTag entries to newTag
      await txn.update('note_tags', {'tag_name': newTag}, where: 'tag_name = ?', whereArgs: [oldTag]);

      // 3. Update the tag metadata in the tags table
      final colorRows = await txn.query(TableNames.tags, columns: [TagFields.color], where: '${TagFields.name} = ?', whereArgs: [oldTag]);
      if (colorRows.isNotEmpty) {
        await txn.insert(TableNames.tags, {TagFields.name: newTag, TagFields.color: colorRows.first[TagFields.color] as int}, conflictAlgorithm: ConflictAlgorithm.replace);
        await txn.delete(TableNames.tags, where: '${TagFields.name} = ?', whereArgs: [oldTag]);
      }
    });
  }

  Future<void> deleteTag(String tag) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('note_tags', where: 'tag_name = ?', whereArgs: [tag]);
      await txn.delete(TableNames.tags, where: '${TagFields.name} = ?', whereArgs: [tag]);
    });
  }

  // Transaction CRUD
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    final id = await db.insert(TableNames.transactions, transaction.toJson());
    return transaction.copy(id: id);
  }

  Future<TransactionModel?> createSmsTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    final id = await db.insert(TableNames.transactions, transaction.toJson(), conflictAlgorithm: ConflictAlgorithm.ignore);
    return id > 0 ? transaction.copy(id: id) : null;
  }

  Future<TransactionModel?> readTransaction(int id) async {
    final db = await instance.database;
    final maps = await db.query(TableNames.transactions, columns: TransactionFields.values, where: '${TransactionFields.id} = ?', whereArgs: [id]);
    return maps.isNotEmpty ? TransactionModel.fromJson(maps.first) : null;
  }

  Future<List<TransactionModel>> readAllTransactions() async {
    final db = await instance.database;
    final result = await db.query(TableNames.transactions, orderBy: '${TransactionFields.date} DESC');
    return result.map((json) => TransactionModel.fromJson(json)).toList();
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.update(TableNames.transactions, transaction.toJson(), where: '${TransactionFields.id} = ?', whereArgs: [transaction.id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(TableNames.transactions, where: '${TransactionFields.id} = ?', whereArgs: [id]);
  }

  Future<List<TransactionModel>> searchTransactions(String keyword) async {
    final db = await instance.database;
    final result = await db.query(TableNames.transactions, where: 'description LIKE ? OR category LIKE ?', whereArgs: ['%$keyword%', '%$keyword%'], orderBy: 'date DESC');
    return result.map((json) => TransactionModel.fromJson(json)).toList();
  }

  Future<TransactionModel?> findReversalTarget(double amount, DateTime date, {int windowDays = 7}) async {
    final db = await instance.database;
    final windowStart = date.subtract(Duration(days: windowDays)).toIso8601String();
    final windowEnd = date.toIso8601String();
    final rows = await db.query(TableNames.transactions, where: 'amount = ? AND isExpense = 1 AND smsId IS NOT NULL AND date >= ? AND date <= ?', whereArgs: [amount, windowStart, windowEnd], orderBy: '${TransactionFields.date} DESC', limit: 1);
    return rows.isNotEmpty ? TransactionModel.fromJson(rows.first) : null;
  }

  Future<bool> smsExists(String smsId) async {
    final db = await instance.database;
    final result = await db.query(TableNames.transactions, columns: [TransactionFields.id], where: '${TransactionFields.smsId} = ?', whereArgs: [smsId], limit: 1);
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getMonthlyTransactionSummary(int months) async {
    final db = await instance.database;
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (int i = months - 1; i >= 0; i--) {
      final periodStart = DateTime(now.year, now.month - i, 1);
      final periodEnd = DateTime(now.year, now.month - i + 1, 1);
      final rows = await db.rawQuery(
          'SELECT SUM(CASE WHEN isExpense = 0 THEN amount ELSE 0.0 END) AS totalIncome, '
          'SUM(CASE WHEN isExpense = 1 THEN amount ELSE 0.0 END) AS totalExpense '
          'FROM ${TableNames.transactions} '
          'WHERE date >= ? AND date < ? AND category != ?',
          [
            periodStart.toIso8601String(),
            periodEnd.toIso8601String(),
            '__reversal__'
          ]);
      result.add({
        'month': periodStart,
        'totalIncome': (rows.first['totalIncome'] as num?)?.toDouble() ?? 0.0,
        'totalExpense': (rows.first['totalExpense'] as num?)?.toDouble() ?? 0.0
      });
    }
    return result;
  }

  Future<Map<String, double>> getAllTimeSummary() async {
    final db = await instance.database;
    final rows = await db.rawQuery(
        'SELECT SUM(CASE WHEN isExpense = 0 THEN amount ELSE 0.0 END) AS totalIncome, '
        'SUM(CASE WHEN isExpense = 1 THEN amount ELSE 0.0 END) AS totalExpense '
        'FROM ${TableNames.transactions} '
        'WHERE category != ?',
        ['__reversal__']);
    return {
      'totalIncome': (rows.first['totalIncome'] as num?)?.toDouble() ?? 0.0,
      'totalExpense': (rows.first['totalExpense'] as num?)?.toDouble() ?? 0.0
    };
  }

  // Category Definition CRUD
  Future<List<CategoryDefinition>> getAllCategoryDefinitions() async {
    final db = await instance.database;
    final rows = await db.query(TableNames.categoryDefinitions, orderBy: '${CategoryFields.isBuiltIn} DESC, ${CategoryFields.name} ASC');
    return rows.map(CategoryDefinition.fromMap).toList();
  }

  Future<void> upsertCategoryDefinition(CategoryDefinition def) async {
    final db = await instance.database;
    await db.insert(TableNames.categoryDefinitions, def.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCategoryDefinition(String name) async {
    final db = await instance.database;
    await db.delete(TableNames.categoryDefinitions, where: '${CategoryFields.name} = ? AND ${CategoryFields.isBuiltIn} = 0', whereArgs: [name]);
  }

  // SMS Contacts CRUD
  Future<List<SmsContact>> getAllSmsContacts() async {
    final db = await instance.database;
    final rows = await db.query(TableNames.smsContacts, orderBy: '${SmsContactFields.isBuiltIn} DESC, ${SmsContactFields.label} ASC, ${SmsContactFields.id} ASC');
    return rows.map(SmsContact.fromMap).toList();
  }

  Future<void> upsertSmsContact(SmsContact contact) async {
    final db = await instance.database;
    await db.insert(TableNames.smsContacts, contact.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSmsContact(String id) async {
    final db = await instance.database;
    await db.delete(TableNames.smsContacts, where: '${SmsContactFields.id} = ? AND ${SmsContactFields.isBuiltIn} = 0', whereArgs: [id]);
  }

  Future<void> setSmsContactBlocked(String id, bool blocked) async {
    final db = await instance.database;
    await db.update(TableNames.smsContacts, {SmsContactFields.isBlocked: blocked ? 1 : 0}, where: '${SmsContactFields.id} = ?', whereArgs: [id]);
  }

  Future<bool> hasCrossSenderDuplicate(double amount, DateTime date) async {
    final db = await instance.database;
    final windowStart = date.subtract(const Duration(minutes: 5)).toIso8601String();
    final windowEnd = date.add(const Duration(minutes: 5)).toIso8601String();
    final rows = await db.query(TableNames.transactions, columns: [TransactionFields.id], where: 'amount = ? AND smsId IS NOT NULL AND date >= ? AND date <= ?', whereArgs: [amount, windowStart, windowEnd], limit: 1);
    return rows.isNotEmpty;
  }

  // Period Tracker CRUD
  Future<PeriodLog> createPeriodLog(PeriodLog log) async {
    final db = await instance.database;
    await db.insert(TableNames.periodLogs, log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return log;
  }

  Future<PeriodLog?> readPeriodLog(String id) async {
    final db = await instance.database;
    final maps = await db.query(TableNames.periodLogs, where: '${PeriodLogFields.id} = ?', whereArgs: [id]);
    return maps.isNotEmpty ? PeriodLog.fromMap(maps.first) : null;
  }

  Future<List<PeriodLog>> readAllPeriodLogs() async {
    final db = await instance.database;
    final result = await db.query(TableNames.periodLogs, orderBy: '${PeriodLogFields.startDate} DESC');
    return result.map((json) => PeriodLog.fromMap(json)).toList();
  }

  Future<int> updatePeriodLog(PeriodLog log) async {
    final db = await instance.database;
    return await db.update(TableNames.periodLogs, log.toMap(), where: '${PeriodLogFields.id} = ?', whereArgs: [log.id]);
  }

  Future<int> deletePeriodLog(String id) async {
    final db = await instance.database;
    return await db.delete(TableNames.periodLogs, where: '${PeriodLogFields.id} = ?', whereArgs: [id]);
  }

  Future<List<PeriodLog>> searchPeriodLogs(String keyword) async {
    final db = await instance.database;
    final result = await db.query(TableNames.periodLogs, where: '${PeriodLogFields.notes} LIKE ? OR ${PeriodLogFields.intensity} LIKE ?', whereArgs: ['%$keyword%', '%$keyword%'], orderBy: '${PeriodLogFields.startDate} DESC');
    return result.map((json) => PeriodLog.fromMap(json)).toList();
  }
}
