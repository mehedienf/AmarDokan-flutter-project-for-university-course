import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:amar_dokan/features/customers/data/models/customer_model.dart';
import 'package:amar_dokan/features/customers/data/services/customer_service.dart';

/// CustomerProvider - Customer feature এর state management
///
/// এই provider:
/// - Customer list hold করে (real-time stream থেকে)
/// - Search query manage করে
/// - Loading ও error state track করে
/// - CRUD operations wrap করে service এর উপর
class CustomerProvider extends ChangeNotifier {
  final CustomerService _service;

  CustomerProvider({CustomerService? service})
      : _service = service ?? CustomerService();

  // ============================================
  // State
  // ============================================

  List<CustomerModel> _customers = [];
  StreamSubscription<List<CustomerModel>>? _subscription;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // ============================================
  // Getters
  // ============================================

  /// সব customers (raw list, no filter)
  List<CustomerModel> get customers => _customers;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message (যদি থাকে)
  String? get errorMessage => _errorMessage;

  /// Current search query
  String get searchQuery => _searchQuery;

  /// Search ও sort করা customer list (UI তে এটা ব্যবহার হবে)
  List<CustomerModel> get filteredCustomers {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? List<CustomerModel>.from(_customers)
        : _customers.where((c) {
            return c.name.toLowerCase().contains(query) ||
                c.phone.toLowerCase().contains(query) ||
                (c.email != null && c.email!.toLowerCase().contains(query));
          }).toList();
    filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return filtered;
  }

  /// Total customer count
  int get totalCustomers => _customers.length;

  /// Active customer count
  int get activeCustomersCount =>
      _customers.where((c) => c.isActive).length;

  /// Total revenue from all customers
  double get totalRevenue =>
      _customers.fold(0.0, (sum, c) => sum + c.totalPurchases);

  /// ID দিয়ে customer খোঁজা
  CustomerModel? getCustomerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
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

    _subscription = _service.getCustomersStream().listen(
      (customers) {
        _customers = customers;
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
  // Search
  // ============================================

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // ============================================
  // CRUD Operations
  // ============================================

  /// নতুন customer add করো
  /// Returns: created customer এর ID
  Future<String> addCustomer(CustomerModel customer) async {
    try {
      return await _service.addCustomer(customer);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Customer update করো
  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      await _service.updateCustomer(customer);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Customer delete করো
  Future<void> deleteCustomer(String customerId) async {
    try {
      await _service.deleteCustomer(customerId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Error clear করা
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
