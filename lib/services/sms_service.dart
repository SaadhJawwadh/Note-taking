import 'dart:async';
import 'package:another_telephony/telephony.dart' hide NetworkType;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/transaction_model.dart';
import '../data/transaction_category.dart';
import 'sms_parser.dart';
import 'sms_constants.dart';
import 'gemini_nano_service.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import 'dart:io';

class SmsService {
  static final Telephony telephony = Telephony.instance;

  static Future<void> _handleNewSms(SmsMessage sms) async {
    await TransactionCategory.reload();
    final transaction = await _parseWithAiFallback(
      body: sms.body ?? '',
      address: sms.address ?? '',
      messageId: sms.id,
      messageDate: sms.date,
      allowedSenderIds: _allowedSenderIds,
      blockedSenderIds: _blockedSenderIds,
      customExpenseRules: _customExpenseRules,
      customIncomeRules: _customIncomeRules,
    );
    if (transaction == null || transaction.smsId == null) {
      return;
    }
    if (await TransactionRepository.instance.hasCrossSenderDuplicate(transaction.amount, transaction.date)) {
      return;
    }

    final inserted = await TransactionRepository.instance.createSmsTransaction(transaction);
    if (inserted == null) {
      return;
    }

    if (transaction.category == SmsConstants.reversalSentinel) {
      final target = await TransactionRepository.instance.findReversalTarget(transaction.amount, transaction.date);
      if (target != null) {
        await TransactionRepository.instance.deleteTransaction(target.id!);
      }
      // Always delete the reversal transaction itself to keep the DB clean
      await TransactionRepository.instance.deleteTransaction(inserted.id!);
    } else {
      await NotificationService.showNotification(
        id: inserted.id ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
        title: inserted.isExpense ? '💳 Expense Auto-Imported' : '💰 Income Auto-Imported',
        body: '${inserted.isExpense ? "Spent" : "Received"} ${inserted.amount.toStringAsFixed(0)} • ${inserted.description}',
      );
    }
  }

  static Set<String> _allowedSenderIds = {};
  static Set<String> _blockedSenderIds = {};
  static var _customExpenseRules = <String>[];
  static var _customIncomeRules = <String>[];

  static Future<void> reloadSmsContacts() async {
    final contacts = await TransactionRepository.instance.getAllSmsContacts();
    final allowed = <String>{};
    final blocked = <String>{};
    for (final c in contacts) {
      if (c.isBlocked) {
        blocked.addAll(c.senderIds.map((s) => s.toLowerCase()));
      } else {
        allowed.addAll(c.senderIds.map((s) => s.toLowerCase()));
      }
    }
    _allowedSenderIds = allowed;
    _blockedSenderIds = blocked;
    try {
      final prefs = await SharedPreferences.getInstance();
      _customExpenseRules = prefs.getStringList('customExpenseRules') ?? [];
      _customIncomeRules = prefs.getStringList('customIncomeRules') ?? [];
    } catch (_) {}
  }

  static Future<bool> requestPermissions() async => (await Permission.sms.request()).isGranted;

  static Future<bool> hasPermission() async => (await Permission.sms.status).isGranted;

  static Future<int> syncInboxFrom(DateTime from) async {
    if (!await hasPermission()) {
      return 0;
    }
    await reloadSmsContacts();
    await TransactionCategory.reload();

    final start = from.millisecondsSinceEpoch;

    final messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE, SmsColumn.ID],
      filter: SmsFilter.where(SmsColumn.DATE).greaterThanOrEqualTo(start.toString()),
    );

    int count = 0;
    for (var m in messages) {
      final t = await _parseWithAiFallback(
        body: m.body ?? '',
        address: m.address ?? '',
        messageId: m.id,
        messageDate: m.date,
        allowedSenderIds: _allowedSenderIds,
        blockedSenderIds: _blockedSenderIds,
        customExpenseRules: _customExpenseRules,
        customIncomeRules: _customIncomeRules,
      );
      if (t == null || t.smsId == null) {
        continue;
      }
      if (await TransactionRepository.instance.hasCrossSenderDuplicate(t.amount, t.date)) {
        continue;
      }

      final inserted = await TransactionRepository.instance.createSmsTransaction(t);
      if (inserted == null) {
        continue;
      }
      count++;

      if (t.category == SmsConstants.reversalSentinel) {
        final target = await TransactionRepository.instance.findReversalTarget(t.amount, t.date);
        if (target != null) {
          await TransactionRepository.instance.deleteTransaction(target.id!);
        }
        await TransactionRepository.instance.deleteTransaction(inserted.id!);
      }
    }
    return count;
  }

  /// Scans recent inbox SMS for unlisted sender handles that look like financial/bank senders.
  static Future<List<String>> discoverNewBankSenders() async {
    if (!await hasPermission()) return [];
    await reloadSmsContacts();

    final messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY],
    );

    final candidates = <String>{};
    for (var m in messages) {
      final address = (m.address ?? '').trim();
      final body = m.body ?? '';
      if (address.isEmpty || body.isEmpty) continue;

      final addrLower = address.toLowerCase();
      if (_allowedSenderIds.contains(addrLower) || _blockedSenderIds.contains(addrLower)) {
        continue;
      }
      final isKnownBank = SmsConstants.bankSenders.any((s) => address.toUpperCase().contains(s.toUpperCase()));
      if (isKnownBank) continue;

      final hasFinancialTerms = SmsConstants.amountRegex.hasMatch(body) ||
          SmsConstants.bareAmountRegex.hasMatch(body) ||
          SmsConstants.debitRegex.hasMatch(body) ||
          SmsConstants.creditRegex.hasMatch(body);

      if (hasFinancialTerms && address.length >= 3) {
        candidates.add(address);
      }
    }
    return candidates.toList();
  }

  static final StreamController<TransactionModel> _smsStreamController = StreamController<TransactionModel>.broadcast();
  static bool _isListeningToTelephony = false;

  static Stream<TransactionModel> get incomingTransactions {
    _startTelephonyListening();
    return _smsStreamController.stream;
  }

  static void _startTelephonyListening() {
    if (_isListeningToTelephony) return;
    _isListeningToTelephony = true;
    
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        await reloadSmsContacts();
        await TransactionCategory.reload();
        await _handleNewSms(message);
        final t = await _parseWithAiFallback(
          body: message.body ?? '',
          address: message.address ?? '',
          messageId: message.id,
          messageDate: message.date,
          allowedSenderIds: _allowedSenderIds,
          blockedSenderIds: _blockedSenderIds,
          customExpenseRules: _customExpenseRules,
          customIncomeRules: _customIncomeRules,
        );
        if (t != null) {
          _smsStreamController.add(t);
        }
      },
      onBackgroundMessage: backgroundMessageHandler,
    );
  }

  @Deprecated('Use incomingTransactions instead to avoid memory leaks')
  static void listenForSms({required Function(TransactionModel) onNew}) {
    incomingTransactions.listen(onNew);
  }

  static Future<TransactionModel?> _parseWithAiFallback({
    required String body,
    required String address,
    required int? messageId,
    required int? messageDate,
    required Set<String> allowedSenderIds,
    required Set<String> blockedSenderIds,
    required List<String> customExpenseRules,
    required List<String> customIncomeRules,
  }) async {
    var transaction = SmsParser.parseMessage(
      body: body,
      address: address,
      messageId: messageId,
      messageDate: messageDate,
      allowedSenderIds: allowedSenderIds,
      blockedSenderIds: blockedSenderIds,
      customExpenseRules: customExpenseRules,
      customIncomeRules: customIncomeRules,
    );

    bool isAiParsed = false;
    if (transaction == null && body.trim().isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final useAi = prefs.getBool('useOnDeviceAi') ?? false;
        if (useAi && SmsParser.isPotentiallyRelevant(
              body: body,
              address: address,
              allowedSenderIds: allowedSenderIds,
              blockedSenderIds: blockedSenderIds,
            )) {
          final aiService = GeminiNanoService();
          if (await aiService.isSupported()) {
            await TransactionCategory.reload();
            final activeCategories = TransactionCategory.allNames;
            final aiParsed = await aiService.parseSmsTransaction(body, activeCategories);
            if (aiParsed != null && aiParsed['amount'] != null && aiParsed['amount'] > 0) {
              final date = messageDate != null
                  ? DateTime.fromMillisecondsSinceEpoch(messageDate)
                  : DateTime.now();
              final smsId = messageId != null
                  ? '${messageId}_$messageDate'
                  : 'hash_${body.hashCode}_$messageDate';

              final description = aiParsed['description'] ?? aiParsed['merchant'] ?? 'AI Parsed Transaction';
              String category = aiParsed['category'] ?? 'Other';
              if (!activeCategories.contains(category)) {
                category = TransactionCategory.fromDescriptionCached('$description $body');
              }

              transaction = TransactionModel(
                amount: aiParsed['amount'],
                description: description,
                date: date,
                isExpense: aiParsed['isExpense'] ?? true,
                category: category,
                smsId: smsId,
              );
              isAiParsed = true;
            }
          }
        }
      } catch (e) {
        debugPrint('On-device AI SMS parsing failed: $e');
      }
    }

    // AI Refinement Step: Only refine the description if it was NOT already parsed by the AI
    if (transaction != null && !isAiParsed) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool('useOnDeviceAi') ?? false) {
          final aiService = GeminiNanoService();
          if (await aiService.isSupported()) {
            final refined = await aiService.refineTransactionDescription(
              transaction.description,
              body,
            );
            if (refined != null && refined.isNotEmpty) {
              transaction = transaction.copy(description: refined);
            }
          }
        }
      } catch (e) {
        debugPrint('AI Refinement failed: $e');
      }
    }

    return transaction;
  }

  static const kDailySyncTaskName = 'com.saadhjawwadh.notebook.dailySync';

  static Duration calculateDailySyncDelay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final now = DateTime.now();
      var target = DateTime(now.year, now.month, now.day, hour, minute);
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }
      return target.difference(now);
    } catch (e) {
      debugPrint('Error calculating delay: $e');
      return const Duration(hours: 24);
    }
  }

  static Future<void> syncDailySyncSchedule() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('dailySyncEnabled') ?? false;

      // Cancel any existing task first to avoid multiple triggers
      await Workmanager().cancelByUniqueName(kDailySyncTaskName);

      if (!enabled) return;

      final timeStr = prefs.getString('dailySyncTime') ?? '20:00';
      final delay = calculateDailySyncDelay(timeStr);

      await Workmanager().registerOneOffTask(
        kDailySyncTaskName,
        kDailySyncTaskName,
        initialDelay: delay,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: true,
        ),
      );
      debugPrint('Daily sync task scheduled with delay: $delay');
    } catch (e) {
      debugPrint('Error scheduling daily sync: $e');
    }
  }

  static Future<bool> performDailyTransactionSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Double-check settings and permission
      if (!(prefs.getBool('dailySyncEnabled') ?? false)) return true;
      if (!await hasPermission()) return true;

      // Sync transactions from the past 24 hours
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));
      final count = await syncInboxFrom(oneDayAgo);

      // Notify the user if new transactions were synced
      if (count > 0) {
        await NotificationService.showNotification(
          id: 101,
          title: 'Daily SMS Sync Complete',
          body: 'Synced $count new transaction${count == 1 ? "" : "s"} from your messages.',
        );
      }

      // Schedule next execution 24 hours later
      final timeStr = prefs.getString('dailySyncTime') ?? '20:00';
      final delay = calculateDailySyncDelay(timeStr);

      await Workmanager().registerOneOffTask(
        kDailySyncTaskName,
        kDailySyncTaskName,
        initialDelay: delay,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: true,
        ),
      );

      return true;
    } catch (e) {
      debugPrint('performDailyTransactionSync error: $e');
      return false;
    }
  }
}

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  // Setup SharedPreferences and database config for the isolate
  final prefs = await SharedPreferences.getInstance();
  final customExpenseRules = prefs.getStringList('customExpenseRules') ?? [];
  final customIncomeRules = prefs.getStringList('customIncomeRules') ?? [];
  
  final contacts = await TransactionRepository.instance.getAllSmsContacts();
  final allowed = <String>{};
  final blocked = <String>{};
  for (final c in contacts) {
    if (c.isBlocked) {
      blocked.addAll(c.senderIds.map((s) => s.toLowerCase()));
    } else {
      allowed.addAll(c.senderIds.map((s) => s.toLowerCase()));
    }
  }

  await TransactionCategory.reload();

  final transaction = await SmsService._parseWithAiFallback(
    body: message.body ?? '',
    address: message.address ?? '',
    messageId: message.id,
    messageDate: message.date,
    allowedSenderIds: allowed,
    blockedSenderIds: blocked,
    customExpenseRules: customExpenseRules,
    customIncomeRules: customIncomeRules,
  );
  if (transaction != null) {
    if (await TransactionRepository.instance.hasCrossSenderDuplicate(transaction.amount, transaction.date)) {
      return;
    }
    final inserted = await TransactionRepository.instance.createSmsTransaction(transaction);
    if (inserted != null) {
      if (transaction.category == SmsConstants.reversalSentinel) {
        final target = await TransactionRepository.instance.findReversalTarget(transaction.amount, transaction.date);
        if (target != null) {
          await TransactionRepository.instance.deleteTransaction(target.id!);
        }
        await TransactionRepository.instance.deleteTransaction(inserted.id!);
      } else {
        await NotificationService.showNotification(
          id: inserted.id ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
          title: inserted.isExpense ? '💳 Expense Auto-Imported' : '💰 Income Auto-Imported',
          body: '${inserted.isExpense ? "Spent" : "Received"} ${inserted.amount.toStringAsFixed(0)} • ${inserted.description}',
        );
      }
    }
  }
}
