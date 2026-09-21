import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/transaction_model.dart';
import '../data/transaction_repository.dart';
import '../../../data/repositories/recurring_rule_repository.dart';
import '../../../services/p2p_sync_service.dart';
import '../../../services/sms_service.dart';

/// ChangeNotifier managing state and financial metrics for Financial Manager.
class FinancialManagerProvider extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository.instance;
  StreamSubscription? _syncSubscription;
  StreamSubscription? _smsSyncSubscription;

  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  List<TransactionModel> _trashedTransactions = [];
  bool _isLoading = false;
  bool _isSmsSyncing = false;
  SmsSyncProgress? _smsSyncProgress;

  FinancialManagerProvider() {
    _syncSubscription = P2pSyncService.instance.syncEvents.listen((result) {
      if (result.success && (result.syncedCount > 0 || result.receivedCount > 0)) {
        loadTransactions();
      }
    });
    _smsSyncSubscription = SmsService.syncProgressStream.listen((progress) {
      _isSmsSyncing = progress.isSyncing;
      _smsSyncProgress = progress;
      if (!progress.isSyncing && progress.found > 0) {
        loadTransactions();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _smsSyncSubscription?.cancel();
    super.dispose();
  }

  String _searchQuery = '';
  String _selectedCategory = 'All';
  DateTime _selectedMonth = DateTime.now();

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  double _dailyCashFlow = 0;
  double _savingsVaultCashFlow = 0;

  List<TransactionModel> get transactions => List.unmodifiable(_filteredTransactions);
  List<TransactionModel> get trashedTransactions => List.unmodifiable(_trashedTransactions);
  bool get isLoading => _isLoading;
  bool get isSmsSyncing => _isSmsSyncing;
  SmsSyncProgress? get smsSyncProgress => _smsSyncProgress;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  DateTime get selectedMonth => _selectedMonth;

  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _balance;
  double get dailyCashFlow => _dailyCashFlow;
  double get savingsVaultCashFlow => _savingsVaultCashFlow;

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      await RecurringRuleRepository.instance.materializeDueRules();
      await _repository.clearOldTransactionTrash(days: 30);
    } catch (_) {}

    _allTransactions = await _repository.readAllTransactions();
    _trashedTransactions = await _repository.readTrashedTransactions();
    _applyFilters();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => loadTransactions();

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = month;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredTransactions = _allTransactions.where((tx) {
      if (tx.category == '__reversal__') return false;

      final matchesQuery = _searchQuery.isEmpty ||
          tx.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' || tx.category == _selectedCategory;

      final matchesMonth = tx.date.year == _selectedMonth.year && tx.date.month == _selectedMonth.month;

      return matchesQuery && matchesCategory && matchesMonth;
    }).toList();

    _calculateTotals();
  }

  void _calculateTotals() {
    _totalIncome = 0;
    _totalExpense = 0;
    _dailyCashFlow = 0;
    _savingsVaultCashFlow = 0;

    for (final tx in _filteredTransactions) {
      final isTransfer = tx.category.toLowerCase() == 'transfer';
      final isSavings = tx.account == 'savings' || tx.account == AccountType.savings;

      if (!isTransfer) {
        if (tx.isExpense) {
          _totalExpense += tx.amount;
        } else {
          _totalIncome += tx.amount;
        }
      }

      final delta = tx.isExpense ? -tx.amount : tx.amount;
      if (isSavings) {
        _savingsVaultCashFlow += delta;
      } else {
        _dailyCashFlow += delta;
      }
    }

    _balance = _totalIncome - _totalExpense;
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _repository.createTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await _repository.softDeleteTransaction(id);
    await loadTransactions();
  }

  Future<void> restoreTransaction(int id) async {
    await _repository.restoreTransaction(id);
    await loadTransactions();
  }

  Future<void> permanentlyDeleteTransaction(int id) async {
    await _repository.permanentlyDeleteTransaction(id);
    await loadTransactions();
  }

  Future<void> emptyTrash() async {
    await _repository.emptyTrash();
    await loadTransactions();
  }

  Future<int> cleanupDuplicates() async {
    final removed = await _repository.cleanupDuplicates();
    if (removed > 0) {
      await loadTransactions();
    }
    return removed;
  }

  // ── Multi-Selection & Batch Operations ──────────────────────────────────
  bool _isSelectionMode = false;
  final Set<int> _selectedTransactionIds = <int>{};

  bool get isSelectionMode => _isSelectionMode;
  Set<int> get selectedTransactionIds => Set.unmodifiable(_selectedTransactionIds);
  int get selectedCount => _selectedTransactionIds.length;

  void startSelection(int id) {
    _isSelectionMode = true;
    _selectedTransactionIds.add(id);
    notifyListeners();
  }

  void toggleSelection(int id) {
    if (_selectedTransactionIds.contains(id)) {
      _selectedTransactionIds.remove(id);
      if (_selectedTransactionIds.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedTransactionIds.add(id);
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  void selectAll(List<TransactionModel> visibleTransactions) {
    _isSelectionMode = true;
    _selectedTransactionIds.clear();
    for (final tx in visibleTransactions) {
      if (tx.id != null) {
        _selectedTransactionIds.add(tx.id!);
      }
    }
    notifyListeners();
  }

  void clearSelection() {
    _isSelectionMode = false;
    _selectedTransactionIds.clear();
    notifyListeners();
  }

  Future<List<int>> bulkDeleteSelected() async {
    final idsToDelete = _selectedTransactionIds.toList();
    if (idsToDelete.isEmpty) return [];
    clearSelection();
    await _repository.bulkDeleteTransactions(idsToDelete);
    await loadTransactions();
    return idsToDelete;
  }

  Future<void> bulkRestore(List<int> ids) async {
    if (ids.isEmpty) return;
    await _repository.bulkRestoreTransactions(ids);
    await loadTransactions();
  }

  Future<void> bulkUpdateCategory(String category) async {
    final ids = _selectedTransactionIds.toList();
    if (ids.isEmpty) return;
    clearSelection();
    await _repository.bulkUpdateCategory(ids, category);
    await loadTransactions();
  }

  Future<void> bulkUpdateAccount(String account) async {
    final ids = _selectedTransactionIds.toList();
    if (ids.isEmpty) return;
    clearSelection();
    await _repository.bulkUpdateAccount(ids, account);
    await loadTransactions();
  }

  Future<int> bulkAiRefineSelected() async {
    final ids = _selectedTransactionIds.toSet();
    if (ids.isEmpty) return 0;
    clearSelection();

    final selectedTxns = _allTransactions.where((t) => t.id != null && ids.contains(t.id)).toList();
    int refinedCount = 0;
    for (final t in selectedTxns) {
      final refined = await SmsService.refineSingleTransactionWithAi(t);
      if (refined != null) {
        final updated = refined.copy(isAiRefined: true);
        await _repository.updateTransaction(updated);
        refinedCount++;
      } else {
        await _repository.updateTransaction(t.copy(isAiRefined: true));
      }
    }
    await loadTransactions();
    return refinedCount;
  }
}
