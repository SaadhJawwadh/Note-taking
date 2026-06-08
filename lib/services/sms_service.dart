import 'dart:async';
import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/transaction_model.dart';
import '../data/transaction_category.dart';
import 'sms_parser.dart';
import 'sms_constants.dart';
import 'gemini_nano_service.dart';
import 'package:flutter/foundation.dart';

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

    if (transaction == null && body.trim().isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final useAi = prefs.getBool('useOnDeviceAi') ?? false;
        if (useAi) {
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

              String category = aiParsed['category'] ?? 'Other';
              if (!activeCategories.contains(category)) {
                category = TransactionCategory.fromDescriptionCached(aiParsed['merchant'] ?? body);
              }

              transaction = TransactionModel(
                amount: aiParsed['amount'],
                description: aiParsed['merchant'] ?? 'AI Parsed Transaction',
                date: date,
                isExpense: aiParsed['isExpense'] ?? true,
                category: category,
                smsId: smsId,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('On-device AI SMS parsing failed: $e');
      }
    }

    // AI Refinement Step: If we have a transaction and AI is enabled, refine the description
    if (transaction != null) {
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

  final transaction = SmsParser.parseMessage(
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
    if (inserted != null && transaction.category == SmsConstants.reversalSentinel) {
      final target = await TransactionRepository.instance.findReversalTarget(transaction.amount, transaction.date);
      if (target != null) {
        await TransactionRepository.instance.deleteTransaction(target.id!);
      }
      await TransactionRepository.instance.deleteTransaction(inserted.id!);
    }
  }
}
