import 'dart:async';
import 'package:another_telephony/telephony.dart' hide NetworkType;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/widgets.dart';
import '../features/finances/data/transaction_repository.dart';
import '../data/transaction_model.dart';
import '../data/transaction_category.dart';
import 'sms_parser.dart';
import 'sms_constants.dart';
import 'gemini_nano_service.dart';
import 'offline_ai_fallback_service.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import 'dart:io';

enum SmsSyncTrigger { manualDashboard, historicalSheet, backgroundScheduled, catchUp }

class SmsSyncProgress {
  final bool isSyncing;
  final int scanned;
  final int total;
  final int found;
  final String? message;

  const SmsSyncProgress({
    required this.isSyncing,
    this.scanned = 0,
    this.total = 0,
    this.found = 0,
    this.message,
  });
}

class SmsService {
  static final Telephony telephony = Telephony.instance;

  static bool _isSyncingLock = false;
  static bool get isSyncing => _isSyncingLock;

  static final StreamController<SmsSyncProgress> _syncProgressController =
      StreamController<SmsSyncProgress>.broadcast();
  static Stream<SmsSyncProgress> get syncProgressStream => _syncProgressController.stream;

  static Future<TransactionModel?> _handleNewSms(SmsMessage sms) async {
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
      return null;
    }
    if (await TransactionRepository.instance.hasCrossSenderDuplicate(transaction.amount, transaction.date)) {
      return null;
    }

    final inserted = await TransactionRepository.instance.createSmsTransaction(transaction);
    if (inserted == null) {
      return null;
    }

    if (transaction.category == SmsConstants.reversalSentinel) {
      final target = await TransactionRepository.instance.findReversalTarget(transaction.amount, transaction.date);
      if (target != null) {
        await TransactionRepository.instance.deleteTransaction(target.id!);
      }
      // Always delete the reversal transaction itself to keep the DB clean
      await TransactionRepository.instance.deleteTransaction(inserted.id!);
      return null;
    } else {
      await NotificationService.showNotification(
        id: inserted.id ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
        title: inserted.isExpense ? '💳 Expense Auto-Imported' : '💰 Income Auto-Imported',
        body: '${inserted.isExpense ? "Spent" : "Received"} ${inserted.amount.toStringAsFixed(0)} • ${inserted.description}',
      );
      return inserted;
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

  static Future<void> init() async {
    try {
      await reloadSmsContacts();
      await TransactionCategory.reload();
      if (await hasPermission()) {
        await _startTelephonyListening();
        await syncDailySyncSchedule();
      }
    } catch (e) {
      debugPrint('SmsService init error: $e');
    }
  }

  static Future<bool> requestPermissions() async {
    final granted = (await Permission.sms.request()).isGranted;
    if (granted) {
      await _startTelephonyListening();
      await syncDailySyncSchedule();
    }
    return granted;
  }

  static Future<bool> hasPermission() async {
    try {
      return (await Permission.sms.status).isGranted;
    } catch (e) {
      debugPrint('SmsService.hasPermission isolate warning: $e');
      return true; // Fallback in background isolate so getInboxSms can attempt scanning
    }
  }

  static Future<int> syncInboxFrom(
    DateTime from, {
    void Function(int scanned, int total, int found)? onProgress,
  }) async {
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
    int processed = 0;
    final total = messages.length;
    onProgress?.call(0, total, 0);

    for (var m in messages) {
      processed++;
      if (processed % 5 == 0) {
        await Future.delayed(Duration.zero);
      }

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
        onProgress?.call(processed, total, count);
        continue;
      }
      if (await TransactionRepository.instance.hasCrossSenderDuplicate(t.amount, t.date)) {
        onProgress?.call(processed, total, count);
        continue;
      }

      final inserted = await TransactionRepository.instance.createSmsTransaction(t);
      if (inserted == null) {
        onProgress?.call(processed, total, count);
        continue;
      }
      count++;
      onProgress?.call(processed, total, count);

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

  static Future<void> _startTelephonyListening() async {
    if (_isListeningToTelephony) return;
    if (!await hasPermission()) return;
    
    _isListeningToTelephony = true;
    try {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) async {
          await reloadSmsContacts();
          await TransactionCategory.reload();
          final inserted = await _handleNewSms(message);
          if (inserted != null) {
            _smsStreamController.add(inserted);
          }
        },
        onBackgroundMessage: backgroundMessageHandler,
      );
    } catch (e) {
      _isListeningToTelephony = false;
      debugPrint('Error starting telephony listener: $e');
    }
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
    if (body.trim().isEmpty) return null;

    TransactionModel? transaction;

    final prefs = await SharedPreferences.getInstance();
    final useAi = prefs.getBool('useOnDeviceAi') ?? false;

    // 1. Try AI-First (Gemini Nano) if enabled and supported
    if (useAi && SmsParser.isPotentiallyRelevant(
          body: body,
          address: address,
          allowedSenderIds: allowedSenderIds,
          blockedSenderIds: blockedSenderIds,
        )) {
      await TransactionCategory.reload();
      final activeCategories = TransactionCategory.allNames;
      final aiService = GeminiNanoService();

      try {
        if (await aiService.isSupported()) {
          final aiParsed = await aiService.parseSmsTransaction(body, activeCategories);
          if (aiParsed != null && aiParsed['amount'] != null && (aiParsed['amount'] as num) > 0) {
            final date = messageDate != null
                ? DateTime.fromMillisecondsSinceEpoch(messageDate)
                : DateTime.now();
            final normalizedBody = body.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
            final smsId = messageId != null
                ? '${messageId}_$messageDate'
                : 'hash_${address.toLowerCase()}_${normalizedBody.hashCode}_$messageDate';

            final description = aiParsed['description'] ?? aiParsed['merchant'] ?? 'AI Parsed Transaction';
            String category = aiParsed['category'] ?? 'Other';
            if (category == 'Other' || !activeCategories.contains(category)) {
              category = TransactionCategory.fromDescriptionCached('$description $body');
            }

            transaction = TransactionModel(
              amount: (aiParsed['amount'] as num).toDouble(),
              description: description,
              date: date,
              isExpense: aiParsed['isExpense'] ?? true,
              category: category,
              smsId: smsId,
            );
          }
        }
      } catch (e) {
        debugPrint('On-device AI SMS parsing failed: $e');
      }
    }

    // 2. Fallback to Regex parser if AI did not return a valid transaction
    if (transaction == null) {
      transaction = SmsParser.parseMessage(
        body: body,
        address: address,
        messageId: messageId,
        messageDate: messageDate,
        allowedSenderIds: allowedSenderIds,
        blockedSenderIds: blockedSenderIds,
        customExpenseRules: customExpenseRules,
        customIncomeRules: customIncomeRules,
      );

      // AI Refinement Step: Refine description of regex-parsed transaction if AI is enabled and supported
      if (transaction != null && useAi) {
        try {
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
        } catch (e) {
          debugPrint('AI Refinement failed: $e');
        }
      }
    }

    // 3. Fallback to Generic Offline NLP Engine if Regex parser also failed
    if (transaction == null &&
        SmsParser.isPotentiallyRelevant(
          body: body,
          address: address,
          allowedSenderIds: allowedSenderIds,
          blockedSenderIds: blockedSenderIds,
        )) {
      await TransactionCategory.reload();
      final activeCategories = TransactionCategory.allNames;
      final aiParsed = OfflineAiFallbackService.parseSmsTransaction(body, activeCategories);

      if (aiParsed != null && aiParsed['amount'] != null && (aiParsed['amount'] as num) > 0) {
        final date = messageDate != null
            ? DateTime.fromMillisecondsSinceEpoch(messageDate)
            : DateTime.now();
        final normalizedBody = body.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
        final smsId = messageId != null
            ? '${messageId}_$messageDate'
            : 'hash_${address.toLowerCase()}_${normalizedBody.hashCode}_$messageDate';

        final description = aiParsed['description'] ?? aiParsed['merchant'] ?? 'Offline Parsed Transaction';
        String category = aiParsed['category'] ?? 'Other';
        if (category == 'Other' || !activeCategories.contains(category)) {
          category = TransactionCategory.fromDescriptionCached('$description $body');
        }

        transaction = TransactionModel(
          amount: (aiParsed['amount'] as num).toDouble(),
          description: description,
          date: date,
          isExpense: aiParsed['isExpense'] ?? true,
          category: category,
          smsId: smsId,
        );
      }
    }

    return transaction;
  }

  /// Unified, thread-safe entry point for SMS synchronization across manual & background triggers.
  static Future<int> performSmsSync({
    required SmsSyncTrigger trigger,
    DateTime? fromTime,
    bool bypassTombstones = false,
    void Function(int scanned, int total, int found)? onProgress,
  }) async {
    if (_isSyncingLock) {
      debugPrint('[SmsService] Sync already active. Skipping trigger: $trigger');
      return 0;
    }
    _isSyncingLock = true;
    _syncProgressController.add(const SmsSyncProgress(isSyncing: true, message: 'Initializing SMS scanner...'));

    try {
      if (!await hasPermission()) {
        _syncProgressController.add(const SmsSyncProgress(isSyncing: false, message: 'SMS permission not granted.'));
        return 0;
      }

      await reloadSmsContacts();
      await TransactionCategory.reload();

      final prefs = await SharedPreferences.getInstance();
      DateTime startCutoff;

      if (fromTime != null) {
        startCutoff = fromTime;
      } else {
        final lastSyncStr = prefs.getString('lastSmsSyncTime');
        final lastSync = lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;
        final maxLookback = DateTime.now().subtract(const Duration(hours: 48));
        startCutoff = (lastSync != null && lastSync.isAfter(maxLookback)) ? lastSync : maxLookback;
      }

      final count = await syncInboxFrom(
        startCutoff,
        onProgress: (scanned, total, found) {
          onProgress?.call(scanned, total, found);
          _syncProgressController.add(SmsSyncProgress(
            isSyncing: true,
            scanned: scanned,
            total: total,
            found: found,
          ));
        },
      );

      final now = DateTime.now();
      await prefs.setString('lastSmsSyncTime', now.toIso8601String());
      await prefs.setInt('lastSmsSyncCount', count);

      _syncProgressController.add(SmsSyncProgress(
        isSyncing: false,
        scanned: 0,
        total: 0,
        found: count,
        message: 'Imported $count transaction${count == 1 ? "" : "s"}',
      ));

      return count;
    } catch (e) {
      debugPrint('SmsService.performSmsSync error: $e');
      _syncProgressController.add(SmsSyncProgress(isSyncing: false, message: 'Sync error: $e'));
      return 0;
    } finally {
      _isSyncingLock = false;
    }
  }

  /// Manually triggers the exact daily auto-sync pipeline (scanning recent SMS)
  /// and updates SharedPreferences last sync stats. Returns the count of imported transactions.
  static Future<int> performDailySyncManualTrigger({
    void Function(int scanned, int total, int found)? onProgress,
  }) async {
    return performSmsSync(
      trigger: SmsSyncTrigger.manualDashboard,
      onProgress: onProgress,
    );
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
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
      );
      debugPrint('Daily SMS Auto-Sync task scheduled for $timeStr with delay: $delay');
    } catch (e) {
      debugPrint('Error scheduling SMS auto-sync: $e');
    }
  }

  static Future<bool> performDailyTransactionSync() async {
    WidgetsFlutterBinding.ensureInitialized();
    bool success = false;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Double-check settings and permission
      if (!(prefs.getBool('dailySyncEnabled') ?? false)) return true;
      if (!await hasPermission()) return true;

      final count = await performSmsSync(trigger: SmsSyncTrigger.backgroundScheduled);

      // Notify the user ONLY if 1 or more new transactions were synced
      if (count > 0) {
        await NotificationService.showNotification(
          id: 101,
          title: '💳 SMS Auto-Sync Complete',
          body: 'Synced $count new bank transaction${count == 1 ? "" : "s"} from your messages.',
        );
      }

      success = true;
    } catch (e) {
      debugPrint('performDailyTransactionSync error: $e');
      success = false;
    } finally {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool('dailySyncEnabled') ?? false) {
          final timeStr = prefs.getString('dailySyncTime') ?? '20:00';
          final delay = calculateDailySyncDelay(timeStr);
          await Workmanager().registerOneOffTask(
            kDailySyncTaskName,
            kDailySyncTaskName,
            initialDelay: delay,
            existingWorkPolicy: ExistingWorkPolicy.replace,
            constraints: Constraints(
              networkType: NetworkType.notRequired,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error re-registering daily sync task: $e');
      }
    }
    return success;
  }

  static Future<void> performAppLaunchCatchUpSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('dailySyncEnabled') ?? false;
      if (!enabled) return;
      if (!await hasPermission()) return;

      final lastSyncStr = prefs.getString('lastSmsSyncTime');
      DateTime from = DateTime.now().subtract(const Duration(hours: 48));
      if (lastSyncStr != null) {
        final parsed = DateTime.tryParse(lastSyncStr);
        if (parsed != null) {
          final maxLookback = DateTime.now().subtract(const Duration(hours: 48));
          from = parsed.isBefore(maxLookback) ? maxLookback : parsed;
        }
      }

      if (DateTime.now().difference(from).inMinutes >= 15) {
        final count = await performSmsSync(
          trigger: SmsSyncTrigger.catchUp,
          fromTime: from,
        );
        debugPrint('App-launch catch-up sync completed: $count transactions imported');
      }
    } catch (e) {
      debugPrint('App-launch catch-up sync error: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
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
  } catch (e) {
    debugPrint('backgroundMessageHandler error: $e');
  }
}
