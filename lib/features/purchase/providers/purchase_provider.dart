import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:amar_dokan/features/purchase/data/models/purchase_model.dart';
import 'package:amar_dokan/features/purchase/data/services/purchase_service.dart';

/// PurchaseProvider - Purchase feature এর state management।
///
/// - Purchases list hold করে (real-time stream থেকে)
/// - Search query, date range, status, payment-status filter manage করে
/// - Loading ও error state track করে
/// - CRUD operations wrap করে service এর উপর
/// - Aggregations provide করে (today/month spent, outstanding amount, etc.)
class PurchaseProvider extends ChangeNotifier {
  final PurchaseService _service;

  PurchaseProvider({PurchaseService? service})
      : _service = service ?? PurchaseService();

  // ============================================
  // State
  // ============================================

  List<PurchaseModel> _purchases = [];
  StreamSubscription<List<PurchaseModel>>? _subscription;

  String _searchQuery = '';
  String? _statusFilter; // null = all, 'completed', 'pending', 'cancelled'
  String? _paymentStatusFilter; // null = all, 'paid', 'unpaid', 'partial'
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = false;
  String? _errorMessage;

  // ============================================
  // Getters
  // ============================================

  List<PurchaseModel> get purchases => _purchases;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;

  String? get statusFilter => _statusFilter;
  String? get paymentStatusFilter => _paymentStatusFilter;

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  bool get hasDateFilter => _startDate != null && _endDate != null;
  bool get hasStatusFilter => _statusFilter != null && _statusFilter != 'all';
  bool get hasPaymentFilter =>
      _paymentStatusFilter != null && _paymentStatusFilter != 'all';

  /// Search + status + payment + date range combined filter
  List<PurchaseModel> get filteredPurchases {
    Iterable<PurchaseModel> result = _purchases;

    // Text search
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((p) =>
          p.invoiceNumber.toLowerCase().contains(q) ||
          (p.supplierName?.toLowerCase().contains(q) ?? false) ||
          (p.supplierInvoice?.toLowerCase().contains(q) ?? false) ||
          (p.notes?.toLowerCase().contains(q) ?? false));
    }

    // Status
    if (_statusFilter != null && _statusFilter != 'all') {
      result = result.where((p) => p.status == _statusFilter);
    }

    // Payment status
    if (_paymentStatusFilter != null && _paymentStatusFilter != 'all') {
      result =
          result.where((p) => p.paymentStatus == _paymentStatusFilter);
    }

    // Date range
    if (_startDate != null && _endDate != null) {
      result = result.where((p) {
        final date = p.purchaseDate ?? p.createdAt;
        return !date.isBefore(_startDate!) && !date.isAfter(_endDate!);
      });
    }

    final list = result.toList();
    list.sort((a, b) {
      final ad = a.purchaseDate ?? a.createdAt;
      final bd = b.purchaseDate ?? b.createdAt;
      return bd.compareTo(ad); // newest first
    });
    return list;
  }

  int get totalPurchases => _purchases.length;
  int get filteredCount => filteredPurchases.length;

  // ============================================
  // Aggregations
  // ============================================

  /// Today's purchases (status completed).
  List<PurchaseModel> get todaysPurchases {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return _purchases.where((p) {
      final date = p.purchaseDate ?? p.createdAt;
      return !date.isBefore(start) &&
          !date.isAfter(end) &&
          p.status == 'completed';
    }).toList();
  }

  double get todaysSpent =>
      todaysPurchases.fold(0.0, (acc, p) => acc + p.total);

  int get todaysPurchasesCount => todaysPurchases.length;

  /// This month's purchases (all statuses).
  List<PurchaseModel> get thisMonthPurchases {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end =
        DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
    return _purchases.where((p) {
      final date = p.purchaseDate ?? p.createdAt;
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  double get thisMonthSpent =>
      thisMonthPurchases.fold(0.0, (acc, p) => acc + p.total);

  /// Total outstanding amount owed to suppliers (sum of positive balances).
  double get totalOutstanding =>
      _purchases.fold(0.0, (acc, p) => acc + p.balance);

  /// All-time spend on completed purchases.
  double get totalSpent => _purchases
      .where((p) => p.status == 'completed')
      .fold(0.0, (acc, p) => acc + p.total);

  int get completedPurchasesCount =>
      _purchases.where((p) => p.status == 'completed').length;

  int get pendingPurchasesCount =>
      _purchases.where((p) => p.status == 'pending').length;

  /// Find a purchase by ID.
  PurchaseModel? getPurchaseById(String id) {
    try {
      return _purchases.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// All purchases for a specific supplier.
  List<PurchaseModel> getPurchasesForSupplier(String supplierId) {
    return _purchases.where((p) => p.supplierId == supplierId).toList();
  }

  /// Map of supplierId -> total spent.
  Map<String, double> get totalSpentBySupplier {
    final map = <String, double>{};
    for (final p in _purchases) {
      if (p.supplierId == null) continue;
      map[p.supplierId!] = (map[p.supplierId!] ?? 0) + p.total;
    }
    return map;
  }

  // ============================================
  // Stream Lifecycle
  // ============================================

  /// Firestore stream থেকে data শুরু করে শুনতে।
  /// Screen initState এ call হবে।
  void startListening() {
    _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _service.getPurchasesStream().listen(
      (purchases) {
        _purchases = purchases;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Stream বন্ধ করা — dispose এ call হবে।
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
  // Filters
  // ============================================

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void clearStatusFilter() {
    _statusFilter = null;
    notifyListeners();
  }

  void setPaymentStatusFilter(String? status) {
    _paymentStatusFilter = status;
    notifyListeners();
  }

  void clearPaymentStatusFilter() {
    _paymentStatusFilter = null;
    notifyListeners();
  }

  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void clearDateRange() {
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  void clearAllFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _paymentStatusFilter = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  // ============================================
  // CRUD Operations
  // ============================================

  /// Generate next invoice number.
  Future<String> generateNextInvoiceNumber() async {
    try {
      return await _service.generateNextInvoiceNumber();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return 'PUR-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// নতুন purchase add করো।
  /// Returns: true on success, false on error।
  Future<bool> addPurchase(PurchaseModel purchase) async {
    try {
      await _service.addPurchase(purchase);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Purchase update করো।
  Future<bool> updatePurchase(PurchaseModel purchase) async {
    try {
      await _service.updatePurchase(purchase);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Record a payment made against a purchase (we pay the supplier).
  /// Mirrors SaleProvider.recordPayment.
  Future<bool> recordPayment({
    required String purchaseId,
    required double amount,
  }) async {
    try {
      await _service.recordPaymentAgainstPurchase(
        purchaseId: purchaseId,
        amount: amount,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Purchase delete করো (stock auto-decrement হবে service এ)।
  Future<bool> deletePurchase(String purchaseId) async {
    try {
      await _service.deletePurchase(purchaseId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Error clear করা।
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}