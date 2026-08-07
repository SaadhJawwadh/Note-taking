import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/transaction_model.dart';
import '../data/transaction_repository.dart';
import '../../../data/repositories/recurring_rule_repository.dart';
import '../../../services/p2p_sync_service.dart';

/// ChangeNotifier managing state and financial metrics for Financial Manager.
class FinancialManagerProvider extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository.instance;
  StreamSubscription? _syncSubscription;

  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  List<TransactionModel> _trashedTransactions = [];
  bool _isLoading = false;

  FinancialManagerProvider() {
    _syncSubscription = P2pSyncService.instance.syncEvents.listen((result) {
      if (result.success && (result.syncedCount > 0 || result.receivedCount > 0)) {
        loadTransactions();
      }
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  String _searchQuery = '';
  String _selectedCategory = 'All';
  DateTime _selectedMonth = DateTime.now();

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;

  List<TransactionModel> get transactions => List.unmodifiable(_filteredTransactions);
  List<TransactionModel> get trashedTransactions => List.unmodifiable(_trashedTransactions);
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  DateTime get selectedMonth => _selectedMonth;

  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _balance;

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

    for (final tx in _filteredTransactions) {
      if (tx.isExpense) {
        _totalExpense += tx.amount;
      } else {
        _totalIncome += tx.amount;
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
}
