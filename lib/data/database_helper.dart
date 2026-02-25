import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'note_model.dart';
import 'transaction_model.dart';
import 'category_definition.dart';
import 'sms_contact.dart';
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
      version: 10,
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
    await db.execute('''
      CREATE TABLE category_definitions (
        name TEXT PRIMARY KEY,
        color INTEGER NOT NULL,
        keywords TEXT NOT NULL DEFAULT '[]',
        isBuiltIn INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await _seedBuiltInCategories(db);
    await db.execute('''
      CREATE TABLE sms_contacts (
        id TEXT PRIMARY KEY,
        senderIds TEXT NOT NULL DEFAULT '[]',
        label TEXT,
        isBuiltIn INTEGER NOT NULL DEFAULT 0,
        isBlocked INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await _seedBuiltInSmsContacts(db);
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
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS category_definitions (
          name TEXT PRIMARY KEY,
          color INTEGER NOT NULL,
          keywords TEXT NOT NULL DEFAULT '[]',
          isBuiltIn INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await _seedBuiltInCategories(db);
    }
    if (oldVersion < 8) {
      // Add Payments and Deposit categories introduced in v1.14
      const newCats = [
        ('Payments', 0xFF795548, [
          'koko instalment', 'koko installment', 'instalment', 'installment',
          'emi', 'koko', 'loan', 'repayment', 'credit card', 'card payment',
          'hire purchase',
        ]),
        ('Deposit', 0xFF00897B, [
          'crm deposit', 'cash deposit', 'deposit', 'credited', 'salary',
          'income',
        ]),
      ];
      for (final (name, color, kws) in newCats) {
        await db.insert(
          'category_definitions',
          {'name': name, 'color': color, 'keywords': jsonEncode(kws), 'isBuiltIn': 1},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
    if (oldVersion < 9) {
      // Add user-managed SMS sender whitelist table (v1.14.1)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sms_whitelist (
          sender TEXT PRIMARY KEY
        )
      ''');
    }
    if (oldVersion < 10) {
      // Replace sms_whitelist with sms_contacts (v1.15.0)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sms_contacts (
          id TEXT PRIMARY KEY,
          senderIds TEXT NOT NULL DEFAULT '[]',
          label TEXT,
          isBuiltIn INTEGER NOT NULL DEFAULT 0,
          isBlocked INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await _seedBuiltInSmsContacts(db);
      // Migrate existing whitelist entries as custom contacts
      final hasOld = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='sms_whitelist'",
      )).isNotEmpty;
      if (hasOld) {
        final oldRows = await db.query('sms_whitelist');
        for (final row in oldRows) {
          final sender = row['sender'] as String;
          await db.insert(
            'sms_contacts',
            {
              'id': sender,
              'senderIds': jsonEncode([sender]),
              'label': null,
              'isBuiltIn': 0,
              'isBlocked': 0,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await db.execute('DROP TABLE sms_whitelist');
      }
    }
  }

  /// Seeds the built-in categories into [db]. Uses ConflictAlgorithm.ignore so
  /// running it more than once (e.g. multiple upgrades) is safe.
  static Future<void> _seedBuiltInCategories(Database db) async {
    final builtIns = [
      (
        'Transport',
        0xFF2196F3,
        [
          'pickme ride', 'pickme express', 'pickme', 'uber', 'ola', 'taxi',
          'cab', 'bus', 'train', 'tuk', 'fuel', 'petrol', 'toll', 'parking',
          'grab',
        ]
      ),
      (
        'Food & Dining',
        0xFFFF9800,
        [
          'pickme food', 'pickme eats', 'uber eats', 'food delivery', 'kfc',
          'mcd', 'mcdonalds', 'pizza', 'dominos', 'domino', 'café', 'cafe',
          'coffee', 'restaurant', 'groceries', 'grocery', 'food', 'keells',
          'arpico', 'cargills', 'burger', 'noodles', 'rice', 'bakery',
          'pastry', 'icecream', 'sushi', 'biryani', 'kottu', 'supermarket',
        ]
      ),
      (
        'Subscriptions',
        0xFF9C27B0,
        [
          'amazon prime', 'netflix', 'spotify', 'youtube', 'apple', 'adobe',
          'canva', 'hulu', 'disney', 'microsoft', 'office365', 'chatgpt',
          'openai', 'icloud', 'subscription',
        ]
      ),
      (
        'Shopping',
        0xFFE91E63,
        [
          'online shopping', 'amazon', 'daraz', 'kapruka', 'ebay',
          'aliexpress', 'fabric', 'clothing',
        ]
      ),
      (
        'Utilities',
        0xFF607D8B,
        [
          'mobile bill', 'phone bill', 'electricity', 'ceb', 'leco', 'water',
          'dialog', 'airtel', 'mobitel', 'slt', 'broadband', 'internet',
          'utility',
        ]
      ),
      (
        'Health',
        0xFF4CAF50,
        [
          'lab test', 'pharmacy', 'hospital', 'doctor', 'medical', 'nawaloka',
          'asiri', 'channel', 'clinic', 'diagnostic', 'medicine',
        ]
      ),
      ('Entertainment', 0xFFFF5722,
        ['cinema', 'cinemax', 'scope', 'movie', 'concert', 'event', 'ticket']),
      ('Payments', 0xFF795548, [
        'koko instalment', 'koko installment', 'instalment', 'installment',
        'emi', 'koko', 'loan', 'repayment', 'credit card', 'card payment',
        'hire purchase',
      ]),
      ('Deposit', 0xFF00897B, [
        'crm deposit', 'cash deposit', 'deposit', 'credited', 'salary',
        'income',
      ]),
      ('Other', 0xFF9E9E9E, <String>[]),
    ];
    for (final (name, color, kws) in builtIns) {
      await db.insert(
        'category_definitions',
        {
          'name': name,
          'color': color,
          'keywords': jsonEncode(kws),
          'isBuiltIn': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  /// Seeds the 10 built-in Sri Lankan bank contacts. Uses ignore so re-running
  /// during multiple migration steps is safe.
  static Future<void> _seedBuiltInSmsContacts(Database db) async {
    final banks = <Map<String, Object?>>[
      {'id': 'commercial_bank', 'senderIds': jsonEncode(['COMBANK', 'Comm-Bank', 'CBSL']), 'label': 'Commercial Bank', 'isBuiltIn': 1, 'isBlocked': 0},
      {'id': 'peoples_bank', 'senderIds': jsonEncode(['PEOBANK', 'PeoplesB', 'PBOCSL', 'PEOPLBK']), 'label': 'Peoples Bank', 'isBuiltIn': 1, 'isBlocked': 0},
      {'id': 'hnb', 'senderIds': jsonEncode(['HNB', 'HNBANK', 'HNBAlerts']), 'label': 'HNB', 'isBuiltIn': 1, 'isBlocked': 0},
      {'id': 'sampath_bank', 'senderIds': jsonEncode(['SAMPATH', 'Sampath', 'SAMPTBK']), 'label': 'Sampath Bank', 'isBuiltIn': 1, 'isBlocked': 0},
      {'id': 'boc', 'senderIds': jsonEncode(['BOCCSL', 'BOC', 'BOCSL']), 'label': 'BOC', 'isBuiltIn': 1, 'isBlocked': 0},
      {'id': 'ndb_bank', 'senderIds': jsonEncode(['NDB', 'NDBBANK']), 'label': 'NDB Bank', 'isBuiltIn': 1, 'isBlocked': 0},
      {'id': 'seylan_bank', 'senderIds': jsonEncode(['SEYLAN', 'Seybank', 'SEYLNBK']), 'label': 'Seylan Bank', 'isBuiltIn': 1, 'isBlocked': 0},
      {'id': 'amana_bank', 'senderIds': jsonEncode(['AMANABNK', 'AMANA', 'AMANABK']), 'label': 'Amana Bank', 'isBuiltIn': 1, 'isBlocked': 0},
      {'id': 'ntb', 'senderIds': jsonEncode(['NTB', 'NTBBANK']), 'label': 'Nations Trust Bank', 'isBuiltIn': 1, 'isBlocked': 0},
      {'id': 'lolc', 'senderIds': jsonEncode(['LOLC']), 'label': 'LOLC Finance', 'isBuiltIn': 1, 'isBlocked': 0},
    ];
    for (final bank in banks) {
      await db.insert('sms_contacts', bank, conflictAlgorithm: ConflictAlgorithm.ignore);
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
    // Read all notes before entering the transaction (avoids re-entrant DB calls).
    final notes = await readAllNotes();
    await db.transaction((txn) async {
      // Update every note that carries the old tag.
      for (var note in notes) {
        if (note.tags.contains(oldTag)) {
          final updatedTags = List<String>.from(note.tags);
          final index = updatedTags.indexOf(oldTag);
          if (index != -1) {
            updatedTags[index] = newTag;
            updatedTags.sort();
            await txn.update(
              'notes',
              {'tags': jsonEncode(updatedTags)},
              where: 'id = ?',
              whereArgs: [note.id],
            );
          }
        }
      }
      // Migrate the color entry atomically.
      final colorRows = await txn.query(
        'tags',
        columns: ['color'],
        where: 'name = ?',
        whereArgs: [oldTag],
      );
      if (colorRows.isNotEmpty) {
        final color = colorRows.first['color'] as int;
        await txn.insert(
          'tags',
          {'name': newTag, 'color': color},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn.delete('tags', where: 'name = ?', whereArgs: [oldTag]);
      }
    });
  }

  Future<void> deleteTag(String tag) async {
    final db = await instance.database;
    // Read all notes before entering the transaction (avoids re-entrant DB calls).
    final notes = await readAllNotes();
    await db.transaction((txn) async {
      // Remove the tag from every note that carries it.
      for (var note in notes) {
        if (note.tags.contains(tag)) {
          final updatedTags = List<String>.from(note.tags)..remove(tag);
          await txn.update(
            'notes',
            {'tags': jsonEncode(updatedTags)},
            where: 'id = ?',
            whereArgs: [note.id],
          );
        }
      }
      // Delete the color entry.
      await txn.delete('tags', where: 'name = ?', whereArgs: [tag]);
    });
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

  /// Returns the most recent SMS-imported expense matching [amount] that was
  /// recorded within [windowDays] days before [date]. Used to locate the
  /// original transaction that a reversal/refund SMS refers to.
  /// Only SMS-imported transactions (smsId IS NOT NULL) are candidates —
  /// manually-entered transactions are never auto-deleted by a reversal.
  Future<TransactionModel?> findReversalTarget(
    double amount,
    DateTime date, {
    int windowDays = 7,
  }) async {
    final db = await instance.database;
    final windowStart =
        date.subtract(Duration(days: windowDays)).toIso8601String();
    final windowEnd = date.toIso8601String();
    final rows = await db.query(
      'transactions',
      where:
          'amount = ? AND isExpense = 1 AND smsId IS NOT NULL AND date >= ? AND date <= ?',
      whereArgs: [amount, windowStart, windowEnd],
      orderBy: '${TransactionFields.date} DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TransactionModel.fromJson(rows.first);
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
        'totalIncome': (rows.first['totalIncome'] as num?)?.toDouble() ?? 0.0,
        'totalExpense': (rows.first['totalExpense'] as num?)?.toDouble() ?? 0.0,
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
      'totalIncome': (rows.first['totalIncome'] as num?)?.toDouble() ?? 0.0,
      'totalExpense': (rows.first['totalExpense'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // ── Category Definition CRUD ──────────────────────────────────────────────

  /// Returns all category definitions: built-in categories first, then custom
  /// categories sorted alphabetically.
  Future<List<CategoryDefinition>> getAllCategoryDefinitions() async {
    final db = await instance.database;
    final rows = await db.query(
      'category_definitions',
      orderBy: 'isBuiltIn DESC, name ASC',
    );
    return rows.map(CategoryDefinition.fromMap).toList();
  }

  /// Inserts or replaces a category definition. Use this for both creating
  /// new custom categories and editing keywords on existing ones.
  Future<void> upsertCategoryDefinition(CategoryDefinition def) async {
    final db = await instance.database;
    await db.insert(
      'category_definitions',
      def.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes a custom (non-built-in) category definition by name.
  /// Built-in categories are silently ignored.
  Future<void> deleteCategoryDefinition(String name) async {
    final db = await instance.database;
    await db.delete(
      'category_definitions',
      where: 'name = ? AND isBuiltIn = 0',
      whereArgs: [name],
    );
  }

  // ── SMS Contacts CRUD ────────────────────────────────────────────────────

  /// Returns all SMS contacts (built-in banks first, then custom).
  Future<List<SmsContact>> getAllSmsContacts() async {
    final db = await instance.database;
    final rows = await db.query(
      'sms_contacts',
      orderBy: 'isBuiltIn DESC, label ASC, id ASC',
    );
    return rows.map(SmsContact.fromMap).toList();
  }

  /// Inserts or replaces an SMS contact. Use for creating custom contacts
  /// or updating existing ones (e.g. editing senderIds).
  Future<void> upsertSmsContact(SmsContact contact) async {
    final db = await instance.database;
    await db.insert(
      'sms_contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes a custom (non-built-in) SMS contact by id.
  Future<void> deleteSmsContact(String id) async {
    final db = await instance.database;
    await db.delete(
      'sms_contacts',
      where: 'id = ? AND isBuiltIn = 0',
      whereArgs: [id],
    );
  }

  /// Toggles the blocked state of an SMS contact.
  Future<void> setSmsContactBlocked(String id, bool blocked) async {
    final db = await instance.database;
    await db.update(
      'sms_contacts',
      {'isBlocked': blocked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns true if a transaction with the same [amount] and smsId exists
  /// within ±5 minutes of [date]. Used for cross-sender deduplication
  /// (e.g. COMBANK and COMBANK Q+ firing for the same real transaction).
  Future<bool> hasCrossSenderDuplicate(double amount, DateTime date) async {
    final db = await instance.database;
    final windowStart =
        date.subtract(const Duration(minutes: 5)).toIso8601String();
    final windowEnd =
        date.add(const Duration(minutes: 5)).toIso8601String();
    final rows = await db.query(
      'transactions',
      columns: [TransactionFields.id],
      where:
          'amount = ? AND smsId IS NOT NULL AND date >= ? AND date <= ?',
      whereArgs: [amount, windowStart, windowEnd],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
