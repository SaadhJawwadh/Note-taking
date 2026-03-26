import 'dart:convert';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'database_constants.dart';
import 'category_constants.dart';

class DatabaseSeed {
  static Future<void> seedBuiltInCategories(Database db) async {
    for (final name in CategoryConstants.all) {
      final color = CategoryConstants.badgeColors[name]?.toARGB32() ?? 0xFF9E9E9E;
      final kws = CategoryConstants.keywords[name] ?? <String>[];
      await db.insert(
        TableNames.categoryDefinitions,
        {
          CategoryFields.name: name,
          CategoryFields.color: color,
          CategoryFields.keywords: jsonEncode(kws),
          CategoryFields.isBuiltIn: 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  static Future<void> seedBuiltInSmsContacts(Database db) async {
    final banks = <Map<String, Object?>>[
      {
        SmsContactFields.id: 'commercial_bank',
        SmsContactFields.senderIds: jsonEncode(['COMBANK', 'Comm-Bank', 'CBSL']),
        SmsContactFields.label: 'Commercial Bank',
        SmsContactFields.isBuiltIn: 1,
        SmsContactFields.isBlocked: 0
      },
      {
        SmsContactFields.id: 'peoples_bank',
        SmsContactFields.senderIds: jsonEncode(['PEOBANK', 'PeoplesB', 'PBOCSL', 'PEOPLBK']),
        SmsContactFields.label: 'Peoples Bank',
        SmsContactFields.isBuiltIn: 1,
        SmsContactFields.isBlocked: 0
      },
      {
        SmsContactFields.id: 'hnb',
        SmsContactFields.senderIds: jsonEncode(['HNB', 'HNBANK', 'HNBAlerts']),
        SmsContactFields.label: 'HNB',
        SmsContactFields.isBuiltIn: 1,
        SmsContactFields.isBlocked: 0
      },
      {
        SmsContactFields.id: 'sampath_bank',
        SmsContactFields.senderIds: jsonEncode(['SAMPATH', 'Sampath', 'SAMPTBK']),
        SmsContactFields.label: 'Sampath Bank',
        SmsContactFields.isBuiltIn: 1,
        SmsContactFields.isBlocked: 0
      },
      {
        SmsContactFields.id: 'boc',
        SmsContactFields.senderIds: jsonEncode(['BOCCSL', 'BOC', 'BOCSL']),
        SmsContactFields.label: 'BOC',
        SmsContactFields.isBuiltIn: 1,
        SmsContactFields.isBlocked: 0
      },
      {
        SmsContactFields.id: 'ndb_bank',
        SmsContactFields.senderIds: jsonEncode(['NDB', 'NDBBANK']),
        SmsContactFields.label: 'NDB Bank',
        SmsContactFields.isBuiltIn: 1,
        SmsContactFields.isBlocked: 0
      },
      {
        SmsContactFields.id: 'seylan_bank',
        SmsContactFields.senderIds: jsonEncode(['SEYLAN', 'Seybank', 'SEYLNBK']),
        SmsContactFields.label: 'Seylan Bank',
        SmsContactFields.isBuiltIn: 1,
        SmsContactFields.isBlocked: 0
      },
      {
        SmsContactFields.id: 'amana_bank',
        SmsContactFields.senderIds: jsonEncode(['AMANABNK', 'AMANA', 'AMANABK']),
        SmsContactFields.label: 'Amana Bank',
        SmsContactFields.isBuiltIn: 1,
        SmsContactFields.isBlocked: 0
      },
      {
        SmsContactFields.id: 'ntb',
        SmsContactFields.senderIds: jsonEncode(['NTB', 'NTBBANK']),
        SmsContactFields.label: 'Nations Trust Bank',
        SmsContactFields.isBuiltIn: 1,
        SmsContactFields.isBlocked: 0
      },
      {
        SmsContactFields.id: 'lolc',
        SmsContactFields.senderIds: jsonEncode(['LOLC']),
        SmsContactFields.label: 'LOLC Finance',
        SmsContactFields.isBuiltIn: 1,
        SmsContactFields.isBlocked: 0
      },
    ];

    for (final bank in banks) {
      await db.insert(
        TableNames.smsContacts,
        bank,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
