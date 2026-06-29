import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/rich_text_utils.dart';
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

  @visibleForTesting
  static void setMockDatabase(Database? db) {
    _database = db;
    _databaseFuture = db != null ? Future.value(db) : null;
  }

  @visibleForTesting
  Future<void> createTestDatabase(Database db) async {
    await _createDB(db, 14);
  }

  Future<Database> get database {
    if (_database != null) return Future.value(_database!);
    
    _databaseFuture ??= _initDB('notes.db').then((db) {
      _database = db;
      return db;
    }).catchError((error) {
      _databaseFuture = null;
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
    
    // Migrate key from SharedPreferences if it exists, then delete it to prevent leakage
    final backupKey = prefs.getString('db_encryption_key_backup');
    if (backupKey != null && backupKey.isNotEmpty) {
      if (key == null || key.isEmpty) {
        key = backupKey;
        try {
          await _secureStorage.write(key: _keyStorageKey, value: key);
        } catch (_) {}
      }
      await prefs.remove('db_encryption_key_backup');
    }

    if (key == null || key.isEmpty) {
      final random = Random.secure();
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      key = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      
      try {
        await _secureStorage.write(key: _keyStorageKey, value: key);
      } catch (_) {}
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
        version: 14,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    } catch (e) {
      if (e.toString().contains('open_failed') || e.toString().contains('26')) {
        debugPrint('DatabaseHelper: Corrupt database detected, backing up...');
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          if (await dbFile.exists()) await dbFile.rename('${path}_corrupt_backup_$timestamp');
          final walFile = File('$path-wal');
          final shmFile = File('$path-shm');
          if (await walFile.exists()) await walFile.rename('$path-wal_corrupt_backup_$timestamp');
          if (await shmFile.exists()) await shmFile.rename('$path-shm_corrupt_backup_$timestamp');
        } catch (backupError) {
          debugPrint('DatabaseHelper: Could not backup corrupt file: $backupError');
        }
        return await openDatabase(
          path,
          password: password,
          version: 14,
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
        ${NoteFields.previewText} TEXT,
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
      await db.execute("INSERT OR IGNORE INTO ${TableNames.categoryDefinitions} (${CategoryFields.name}, ${CategoryFields.color}, ${CategoryFields.keywords}, ${CategoryFields.isBuiltIn}) VALUES ('Payments', 0xFF795548, '[\"koko instalment\", \"koko installment\", \"instalment\", \"installment\", \"emi\", \"koko\", \"loan\", \"repayment\", \"credit card\", \"card payment\", \"hire purchase\"]', 1)");
      await db.execute("INSERT OR IGNORE INTO ${TableNames.categoryDefinitions} (${CategoryFields.name}, ${CategoryFields.color}, ${CategoryFields.keywords}, ${CategoryFields.isBuiltIn}) VALUES ('Deposit', 0xFF00897B, '[\"crm deposit\", \"cash deposit\", \"deposit\", \"credited\", \"salary\", \"income\"]', 1)");
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
          await db.insert(TableNames.smsContacts, {SmsContactFields.id: sender, SmsContactFields.senderIds: '["$sender"]', SmsContactFields.label: null, SmsContactFields.isBuiltIn: 0, SmsContactFields.isBlocked: 0}, conflictAlgorithm: ConflictAlgorithm.ignore);
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
    }
    if (oldVersion < 14) {
      await db.execute('ALTER TABLE ${TableNames.notes} ADD COLUMN ${NoteFields.previewText} TEXT');
      // Populate previews for existing notes
      final notes = await db.query(TableNames.notes, columns: [NoteFields.id, NoteFields.content]);
      for (final note in notes) {
        final id = note[NoteFields.id] as String;
        final content = note[NoteFields.content] as String;
        final preview = RichTextUtils.contentToPlainText(content, maxLines: 6);
        await db.update(TableNames.notes, {NoteFields.previewText: preview}, where: '${NoteFields.id} = ?', whereArgs: [id]);
      }
    }
  }
}
