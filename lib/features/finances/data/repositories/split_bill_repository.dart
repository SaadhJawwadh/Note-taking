import 'package:flutter/material.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../../../data/database_helper.dart';
import '../../../../data/database_constants.dart';
import '../../../../data/transaction_model.dart';
import '../models/split_bill_model.dart';

class SplitBillRepository {
  static final SplitBillRepository instance = SplitBillRepository._();
  SplitBillRepository._();

  DatabaseHelper get _dbHelper => DatabaseHelper.instance;

  Future<List<SplitBillModel>> getSplitBills({
    bool includeSettled = true,
    String? groupTag,
  }) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>['${SplitBillFields.deletedAt} IS NULL'];
    final whereArgs = <dynamic>[];

    if (!includeSettled) {
      whereClauses.add("${SplitBillFields.status} != 'settled'");
    }

    if (groupTag != null && groupTag.trim().isNotEmpty && groupTag != 'All') {
      whereClauses.add('${SplitBillFields.groupTag} = ?');
      whereArgs.add(groupTag.trim());
    }

    final billMaps = await db.query(
      TableNames.splitBills,
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: '${SplitBillFields.date} DESC',
    );

    if (billMaps.isEmpty) return [];

    final billIds = billMaps.map((b) => b[SplitBillFields.id] as String).toList();
    final participantsMap = await _getParticipantsForBills(db, billIds);

    return billMaps.map((map) {
      final billId = map[SplitBillFields.id] as String;
      final participants = participantsMap[billId] ?? [];
      return SplitBillModel.fromMap(map, participants: participants);
    }).toList();
  }

  Future<Map<String, List<SplitParticipantModel>>> _getParticipantsForBills(
    Database db,
    List<String> billIds,
  ) async {
    if (billIds.isEmpty) return {};
    final placeholders = List.filled(billIds.length, '?').join(',');
    final participantMaps = await db.query(
      TableNames.splitParticipants,
      where: '${SplitParticipantFields.billId} IN ($placeholders)',
      whereArgs: billIds,
    );

    final result = <String, List<SplitParticipantModel>>{};
    for (final pMap in participantMaps) {
      final p = SplitParticipantModel.fromMap(pMap);
      result.putIfAbsent(p.billId, () => []).add(p);
    }
    return result;
  }

  Future<SplitBillModel?> getBillById(String id) async {
    final db = await _dbHelper.database;
    final billMaps = await db.query(
      TableNames.splitBills,
      where: '${SplitBillFields.id} = ?',
      whereArgs: [id],
    );
    if (billMaps.isEmpty) return null;

    final participantMaps = await db.query(
      TableNames.splitParticipants,
      where: '${SplitParticipantFields.billId} = ?',
      whereArgs: [id],
    );
    final participants = participantMaps.map((m) => SplitParticipantModel.fromMap(m)).toList();

    return SplitBillModel.fromMap(billMaps.first, participants: participants);
  }

  Future<SplitBillModel?> getBillByTransactionId(int transactionId) async {
    final db = await _dbHelper.database;
    final billMaps = await db.query(
      TableNames.splitBills,
      where: '${SplitBillFields.transactionId} = ? AND ${SplitBillFields.deletedAt} IS NULL',
      whereArgs: [transactionId],
    );
    if (billMaps.isEmpty) return null;

    final billId = billMaps.first[SplitBillFields.id] as String;
    final participantMaps = await db.query(
      TableNames.splitParticipants,
      where: '${SplitParticipantFields.billId} = ?',
      whereArgs: [billId],
    );
    final participants = participantMaps.map((m) => SplitParticipantModel.fromMap(m)).toList();

    return SplitBillModel.fromMap(billMaps.first, participants: participants);
  }

  Future<void> insertSplitBill(SplitBillModel bill) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        TableNames.splitBills,
        bill.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final p in bill.participants) {
        await txn.insert(
          TableNames.splitParticipants,
          p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Update contacts directory
        if (p.contactName.trim().toLowerCase() != 'you' && p.contactName.trim().isNotEmpty) {
          await _saveContactInternal(txn, p.contactName.trim());
        }
      }

      if (!bill.isPayerUser && bill.payerName.trim().toLowerCase() != 'you') {
        await _saveContactInternal(txn, bill.payerName.trim());
      }
    });
  }

  Future<void> updateSplitBill(SplitBillModel bill) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        TableNames.splitBills,
        bill.toMap(),
        where: '${SplitBillFields.id} = ?',
        whereArgs: [bill.id],
      );

      // Re-sync participants
      await txn.delete(
        TableNames.splitParticipants,
        where: '${SplitParticipantFields.billId} = ?',
        whereArgs: [bill.id],
      );

      for (final p in bill.participants) {
        await txn.insert(
          TableNames.splitParticipants,
          p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (p.contactName.trim().toLowerCase() != 'you' && p.contactName.trim().isNotEmpty) {
          await _saveContactInternal(txn, p.contactName.trim());
        }
      }

      // Propagate changes to linked ledger transaction if present
      if (bill.transactionId != null) {
        await txn.update(
          TableNames.transactions,
          {
            TransactionFields.amount: bill.totalAmount,
            TransactionFields.description: bill.title,
            TransactionFields.date: bill.date.toIso8601String(),
          },
          where: '${TransactionFields.id} = ?',
          whereArgs: [bill.transactionId],
        );
      }
    });
  }

  Future<void> toggleParticipantPaid(String participantId, bool hasPaid) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      await txn.update(
        TableNames.splitParticipants,
        {
          SplitParticipantFields.hasPaid: hasPaid ? 1 : 0,
          SplitParticipantFields.paidAt: hasPaid ? now : null,
        },
        where: '${SplitParticipantFields.id} = ?',
        whereArgs: [participantId],
      );

      // Find parent bill and update status
      final pMaps = await txn.query(
        TableNames.splitParticipants,
        where: '${SplitParticipantFields.id} = ?',
        whereArgs: [participantId],
      );
      if (pMaps.isNotEmpty) {
        final billId = pMaps.first[SplitParticipantFields.billId] as String;
        final allPMaps = await txn.query(
          TableNames.splitParticipants,
          where: '${SplitParticipantFields.billId} = ?',
          whereArgs: [billId],
        );
        final participants = allPMaps.map((m) => SplitParticipantModel.fromMap(m)).toList();
        final billMap = await txn.query(
          TableNames.splitBills,
          where: '${SplitBillFields.id} = ?',
          whereArgs: [billId],
        );
        if (billMap.isNotEmpty) {
          final bill = SplitBillModel.fromMap(billMap.first, participants: participants);
          final derivedStatus = bill.computeDerivedStatus();
          await txn.update(
            TableNames.splitBills,
            {SplitBillFields.status: derivedStatus.name},
            where: '${SplitBillFields.id} = ?',
            whereArgs: [billId],
          );
        }
      }
    });
  }

  Future<void> settleAllForContact(String contactName) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      // Mark as paid in all active bills
      await txn.rawUpdate('''
        UPDATE ${TableNames.splitParticipants}
        SET ${SplitParticipantFields.hasPaid} = 1, ${SplitParticipantFields.paidAt} = ?
        WHERE LOWER(TRIM(${SplitParticipantFields.contactName})) = ? AND ${SplitParticipantFields.hasPaid} = 0
      ''', [now, contactName.trim().toLowerCase()]);

      // If contact was payer of bills where user owed, mark bill settled and mark user share as paid
      await txn.rawUpdate('''
        UPDATE ${TableNames.splitBills}
        SET ${SplitBillFields.status} = 'settled'
        WHERE LOWER(TRIM(${SplitBillFields.payerName})) = ? AND ${SplitBillFields.isPayerUser} = 0
      ''', [contactName.trim().toLowerCase()]);

      await txn.rawUpdate('''
        UPDATE ${TableNames.splitParticipants}
        SET ${SplitParticipantFields.hasPaid} = 1, ${SplitParticipantFields.paidAt} = ?
        WHERE LOWER(TRIM(${SplitParticipantFields.contactName})) = 'you'
          AND ${SplitParticipantFields.billId} IN (
            SELECT ${SplitBillFields.id} FROM ${TableNames.splitBills}
            WHERE LOWER(TRIM(${SplitBillFields.payerName})) = ? AND ${SplitBillFields.isPayerUser} = 0
          )
      ''', [now, contactName.trim().toLowerCase()]);

      // Refresh statuses of all bills where this contact was a participant
      final updatedBills = await txn.rawQuery('''
        SELECT DISTINCT ${SplitParticipantFields.billId} FROM ${TableNames.splitParticipants}
        WHERE LOWER(TRIM(${SplitParticipantFields.contactName})) = ?
      ''', [contactName.trim().toLowerCase()]);

      for (final row in updatedBills) {
        final billId = row[SplitParticipantFields.billId] as String;
        final allPMaps = await txn.query(
          TableNames.splitParticipants,
          where: '${SplitParticipantFields.billId} = ?',
          whereArgs: [billId],
        );
        final participants = allPMaps.map((m) => SplitParticipantModel.fromMap(m)).toList();
        final billMap = await txn.query(
          TableNames.splitBills,
          where: '${SplitBillFields.id} = ?',
          whereArgs: [billId],
        );
        if (billMap.isNotEmpty) {
          final bill = SplitBillModel.fromMap(billMap.first, participants: participants);
          final derivedStatus = bill.computeDerivedStatus();
          await txn.update(
            TableNames.splitBills,
            {SplitBillFields.status: derivedStatus.name},
            where: '${SplitBillFields.id} = ?',
            whereArgs: [billId],
          );
        }
      }
    });
  }

  Future<void> softDeleteSplitBill(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      await txn.update(
        TableNames.splitBills,
        {SplitBillFields.deletedAt: now},
        where: '${SplitBillFields.id} = ?',
        whereArgs: [id],
      );

      final maps = await txn.query(
        TableNames.splitBills,
        columns: [SplitBillFields.transactionId],
        where: '${SplitBillFields.id} = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty && maps.first[SplitBillFields.transactionId] != null) {
        final txId = maps.first[SplitBillFields.transactionId] as int;
        await txn.update(
          TableNames.transactions,
          {TransactionFields.deletedAt: now},
          where: '${TransactionFields.id} = ?',
          whereArgs: [txId],
        );
      }
    });
  }

  Future<void> restoreSplitBill(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        TableNames.splitBills,
        {SplitBillFields.deletedAt: null},
        where: '${SplitBillFields.id} = ?',
        whereArgs: [id],
      );

      final maps = await txn.query(
        TableNames.splitBills,
        columns: [SplitBillFields.transactionId],
        where: '${SplitBillFields.id} = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty && maps.first[SplitBillFields.transactionId] != null) {
        final txId = maps.first[SplitBillFields.transactionId] as int;
        await txn.update(
          TableNames.transactions,
          {TransactionFields.deletedAt: null},
          where: '${TransactionFields.id} = ?',
          whereArgs: [txId],
        );
      }
    });
  }

  Future<void> permanentlyDeleteSplitBill(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        TableNames.splitParticipants,
        where: '${SplitParticipantFields.billId} = ?',
        whereArgs: [id],
      );
      await txn.delete(
        TableNames.splitBills,
        where: '${SplitBillFields.id} = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<SplitContactModel>> getRecentContacts({int limit = 20}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      TableNames.splitContacts,
      orderBy: '${SplitContactFields.lastUsed} DESC',
      limit: limit,
    );
    return maps.map((m) => SplitContactModel.fromMap(m)).toList();
  }

  Future<void> saveContact(String name, {String? phoneNumber, int? colorValue}) async {
    final db = await _dbHelper.database;
    await _saveContactInternal(db, name, phoneNumber: phoneNumber, colorValue: colorValue);
  }

  Future<void> _saveContactInternal(
    DatabaseExecutor db,
    String name, {
    String? phoneNumber,
    int? colorValue,
  }) async {
    if (name.trim().isEmpty || name.trim().toLowerCase() == 'you') return;
    final cleanName = name.trim();
    final defaultColors = [
      Colors.indigo.toARGB32(),
      Colors.teal.toARGB32(),
      Colors.deepOrange.toARGB32(),
      Colors.purple.toARGB32(),
      Colors.blue.toARGB32(),
      Colors.amber.toARGB32(),
      Colors.cyan.toARGB32(),
    ];
    final color = colorValue ?? defaultColors[cleanName.hashCode.abs() % defaultColors.length];

    await db.insert(
      TableNames.splitContacts,
      {
        SplitContactFields.name: cleanName,
        SplitContactFields.phoneNumber: phoneNumber,
        SplitContactFields.colorValue: color,
        SplitContactFields.lastUsed: DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, double>> getSummaryMetrics() async {
    final bills = await getSplitBills(includeSettled: false);
    double totalOwedToUser = 0.0;
    double totalUserOwes = 0.0;

    for (final bill in bills) {
      if (bill.isPayerUser) {
        totalOwedToUser += bill.totalOwedToUser;
      } else {
        totalUserOwes += bill.totalUserOwes;
      }
    }

    return {
      'owedToUser': totalOwedToUser,
      'userOwes': totalUserOwes,
      'netBalance': totalOwedToUser - totalUserOwes,
    };
  }

  Future<Map<String, double>> getContactNetBalances() async {
    final bills = await getSplitBills(includeSettled: false);
    final balances = <String, double>{};

    for (final bill in bills) {
      if (bill.isPayerUser) {
        // Participants owe user
        for (final p in bill.participants) {
          if (!p.hasPaid && p.contactName.trim().toLowerCase() != 'you') {
            final key = p.contactName.trim();
            balances[key] = (balances[key] ?? 0.0) + p.shareAmount;
          }
        }
      } else {
        // User owes payer
        if (!bill.isUserSharePaid) {
          final key = bill.payerName.trim();
          balances[key] = (balances[key] ?? 0.0) - bill.userShare;
        }
      }
    }

    return balances;
  }
}
