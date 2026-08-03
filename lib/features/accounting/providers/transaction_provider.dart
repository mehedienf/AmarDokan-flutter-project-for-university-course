import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:amar_dokan/features/accounting/data/models/transaction_model.dart';
import 'package:amar_dokan/features/accounting/data/services/transaction_service.dart';

/// TransactionProvider - Accounting feature এর state management।
class TransactionProvider extends ChangeNotifier {
  final TransactionService _service;

  TransactionProvider({TransactionService? service})
      : _service = service ?? TransactionService();

  // ============================================
  // State
  // ============================================

  List<TransactionModel> _transactions = [];
  StreamSubscription<List<TransactionModel>>? _subscription;

  String _searchQuery = '';
  TransactionType? _typeFilter;
  TransactionCategory? _categoryFilter;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = false;
  String? _errorMessage;

  // ============================================
  // Getters
  // ============================================

  List<TransactionModel> get transactions => _transactions;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  TransactionType? get typeFilter => _typeFilter;
  TransactionCategory? get categoryFilter => _categoryFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  bool get hasDateFilter => _startDate != null && _endDate != null;
  bool get hasTypeFilter => _typeFilter != null;
  bool get hasCategoryFilter => _categoryFilter != null;

  /// All filters combined (search + type + category + date range).
  List<TransactionModel> get filteredTransactions {
    Iterable<TransactionModel> result = _transactions;

    // Text search
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((t) =>
          t.referenceNumber.toLowerCase().contains(q) ||
          (t.partyName?.toLowerCase().contains(q) ?? false) ||
          (t.description?.toLowerCase().contains(q) ?? false) ||
          (t.notes?.toLowerCase().contains(q) ?? false) ||
          t.category.label.toLowerCase().contains(q));
    }

    // Type filter
    if (_typeFilter != null) {
      result = result.where((t) => t.type == _typeFilter);
    }

    // Category filter
    if (_categoryFilter != null) {
      result = result.where((t) => t.category == _categoryFilter);
    }

    // Date range
    if (_startDate != null && _endDate != null) {
      result = result.where((t) {
        final date = t.transactionDate;
        return !date.isBefore(_startDate!) && !date.isAfter(_endDate!);
      });
    }

    final list = result.toList();
    list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return list;
  }

  int get totalTransactions => _transactions.length;
  int get filteredCount => filteredTransactions.length;

  // ============================================
  // Computed totals (based on filtered set)
  // ============================================

  double get totalIncome => filteredTransactions
      .where((t) => t.isIncome)
      .fold<double>(0, (sum, t) => sum + t.amount);

  double get totalExpense => filteredTransactions
      .where((t) => t.isExpense)
      .fold<double>(0, (sum, t) => sum + t.amount);

  double get netCashFlow => totalIncome - totalExpense;
  /// Sum for today only (all categories, signed).
  double get todaysNet {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _transactions
        .where((t) =>
            !t.transactionDate.isBefore(start) &&
            !t.transactionDate.isAfter(end))
        .fold<double>(0, (sum, t) => sum + t.signedAmount);
  }

  double get todaysIncome {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _transactions
        .where((t) =>
            t.isIncome &&
            !t.transactionDate.isBefore(start) &&
            !t.transactionDate.isAfter(end))
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  double get todaysExpense {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _transactions
        .where((t) =>
            t.isExpense &&
            !t.transactionDate.isBefore(start) &&
            !t.transactionDate.isAfter(end))
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  double get thisMonthIncome {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return _transactions
        .where((t) =>
            t.isIncome &&
            !t.transactionDate.isBefore(start) &&
            t.transactionDate.isBefore(end))
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  double get thisMonthExpense {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return _transactions
        .where((t) =>
            t.isExpense &&
            !t.transactionDate.isBefore(start) &&
            t.transactionDate.isBefore(end))
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  double get thisMonthNet => thisMonthIncome - thisMonthExpense;

  /// Grouped totals by category (filtered set).
  Map<TransactionCategory, double> get totalsByCategory {
    final map = <TransactionCategory, double>{};
    for (final t in filteredTransactions) {
      map.update(t.category, (v) => v + t.amount, ifAbsent: () => t.amount);
    }
    return map;
  }
  // ============================================
  // Lifecycle
  // ============================================

  /// Subscribe to the live transaction stream.
  void startListening() {
    _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _service.getTransactionsStream().listen(
      (list) {
        _transactions = list;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object e) {
        _isLoading = false;
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  /// Unsubscribe from the transaction stream.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  // ============================================
  // Filter setters
  // ============================================

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setTypeFilter(TransactionType? type) {
    _typeFilter = type;
    if (type != null &&
        _categoryFilter != null &&
        _categoryFilter!.type != type) {
      _categoryFilter = null;
    }
    notifyListeners();
  }

  void setCategoryFilter(TransactionCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void clearDateFilter() {
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _typeFilter = null;
    _categoryFilter = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================
  // CRUD wrappers
  // ============================================

  Future<String> addTransaction(TransactionModel transaction) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final id = await _service.addTransaction(transaction);
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.updateTransaction(transaction);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.deleteTransaction(transactionId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<TransactionModel?> getTransaction(String transactionId) {
    return _service.getTransaction(transactionId);
  }

  Future<String> generateNextReferenceNumber() {
    return _service.generateNextReferenceNumber();
  }
}
