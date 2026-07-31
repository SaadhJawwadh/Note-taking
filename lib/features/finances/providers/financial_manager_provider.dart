import 'package:flutter/material.dart';
import '../../../data/transaction_model.dart';
import '../data/transaction_repository.dart';
import '../../../data/repositories/recurring_rule_repository.dart';

/// ChangeNotifier managing state and financial metrics for Financial Manager.
class FinancialManagerProvider extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository.instance;

  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = false;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  DateTime _selectedMonth = DateTime.now();

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;

  List<TransactionModel> get transactions => List.unmodifiable(_filteredTransactions);
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
    } catch (_) {}

    _allTransactions = await _repository.readAllTransactions();
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
    await _repository.deleteTransaction(id);
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
