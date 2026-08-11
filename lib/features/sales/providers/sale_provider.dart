import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:amar_dokan/features/sales/data/models/sale_model.dart';
import 'package:amar_dokan/features/sales/data/services/sale_service.dart';

/// SaleProvider - Sales feature এর state management
///
/// এই provider:
/// - Sales list hold করে (real-time stream থেকে)
/// - Search query, date range, payment status filter manage করে
/// - Loading ও error state track করে
/// - CRUD operations wrap করে service এর উপর
/// - Aggregations provide করে (today/month revenue, profit, etc.)
class SaleProvider extends ChangeNotifier {
  final SaleService _service;

  SaleProvider({SaleService? service})
      : _service = service ?? SaleService();

  // ============================================
  // State
  // ============================================

  List<SaleModel> _sales = [];
  StreamSubscription<List<SaleModel>>? _subscription;
  String _searchQuery = '';
  String? _paymentStatusFilter; // null = all, 'paid', 'unpaid', 'partial'
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _errorMessage;

  // ============================================
  // Getters
  // ============================================

  List<SaleModel> get sales => _sales;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;

  String? get paymentStatusFilter => _paymentStatusFilter;

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  bool get hasDateFilter => _startDate != null && _endDate != null;
  bool get hasPaymentFilter =>
      _paymentStatusFilter != null && _paymentStatusFilter != 'all';

  /// Search + payment status + date range combined filter
  List<SaleModel> get filteredSales {
    Iterable<SaleModel> result = _sales;

    // Text search
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((s) =>
          s.invoiceNumber.toLowerCase().contains(q) ||
          (s.customerName?.toLowerCase().contains(q) ?? false) ||
          (s.notes?.toLowerCase().contains(q) ?? false));
    }

    // Payment status
    if (_paymentStatusFilter != null && _paymentStatusFilter != 'all') {
      result = result.where((s) => s.paymentStatus == _paymentStatusFilter);
    }

    // Date range
    if (_startDate != null && _endDate != null) {
      result = result.where((s) {
        final date = s.saleDate ?? s.createdAt;
        return !date.isBefore(_startDate!) && !date.isAfter(_endDate!);
      });
    }

    final list = result.toList();
    list.sort((a, b) {
      final ad = a.saleDate ?? a.createdAt;
      final bd = b.saleDate ?? b.createdAt;
      return bd.compareTo(ad); // newest first
    });
    return list;
  }

  /// Total count of all sales (regardless of filter)
  int get totalSales => _sales.length;

  /// Number of sales matching current filters
  int get filteredCount => filteredSales.length;

  // ============================================
  // Aggregations
  // ============================================

  /// Today's sales (status completed)
  List<SaleModel> get todaysSales {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return _sales.where((s) {
      final date = s.saleDate ?? s.createdAt;
      return !date.isBefore(start) &&
          !date.isAfter(end) &&
          s.status == 'completed';
    }).toList();
  }

  /// Total revenue today (completed sales)
  double get todaysRevenue => todaysSales.fold(
      0.0, (total, s) => total + s.total);

  /// Total profit today
  double get todaysProfit => todaysSales.fold(
      0.0, (total, s) => total + s.totalProfit);

  /// Number of sales today
  int get todaysSalesCount => todaysSales.length;

  /// This month's sales
  List<SaleModel> get thisMonthSales {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1).subtract(
        const Duration(seconds: 1));
    return _sales.where((s) {
      final date = s.saleDate ?? s.createdAt;
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  /// Total revenue this month
  double get thisMonthRevenue =>
      thisMonthSales.fold(0.0, (total, s) => total + s.total);

  /// Total profit this month
  double get thisMonthProfit =>
      thisMonthSales.fold(0.0, (total, s) => total + s.totalProfit);

  /// Total outstanding amount (unpaid/partial)
  double get totalPendingAmount => _sales.fold(
      0.0, (total, s) => total + s.balance);

  /// All-time revenue from completed sales
  double get totalRevenue => _sales
      .where((s) => s.status == 'completed')
      .fold(0.0, (total, s) => total + s.total);

  /// All-time profit from completed sales
  double get totalProfit => _sales
      .where((s) => s.status == 'completed')
      .fold(0.0, (total, s) => total + s.totalProfit);

  /// Count of completed sales
  int get completedSalesCount =>
      _sales.where((s) => s.status == 'completed').length;

  /// ID দিয়ে sale খোঁজা
  SaleModel? getSaleById(String id) {
    try {
      return _sales.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Sales for a specific customer
  List<SaleModel> getSalesForCustomer(String customerId) {
    return _sales.where((s) => s.customerId == customerId).toList();
  }

  // ============================================
  // Stream Lifecycle
  // ============================================

  /// Firestore stream থেকে data শুরু করে শুনতে
  /// Screen initState এ call হবে
  void startListening() {
    _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _service.getSalesStream().listen(
      (sales) {
        _sales = sales;
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

  /// Stream বন্ধ করা — dispose এ call হবে
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
    _paymentStatusFilter = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  // ============================================
  // CRUD Operations
  // ============================================

  /// Generate next invoice number
  Future<String> generateNextInvoiceNumber() async {
    try {
      return await _service.generateNextInvoiceNumber();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return 'INV-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// নতুন sale add করো
  /// Returns: true on success, false on error
  Future<bool> addSale(SaleModel sale) async {
    try {
      await _service.addSale(sale);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sale update করো
  Future<bool> updateSale(SaleModel sale) async {
    try {
      await _service.updateSale(sale);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Record a payment received against a sale (e.g. customer paying off
  /// a partial sale). The Firestore stream will refresh `_sales` and the
  /// Due screen will show the reduced balance automatically.
  Future<bool> recordPayment({
    required String saleId,
    required double amount,
  }) async {
    try {
      await _service.recordPaymentAgainstSale(
        saleId: saleId,
        amount: amount,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sale delete করো
  Future<bool> deleteSale(String saleId) async {
    try {
      await _service.deleteSale(saleId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Error clear করা
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
