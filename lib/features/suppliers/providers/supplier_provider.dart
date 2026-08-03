import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:amar_dokan/features/suppliers/data/models/supplier_model.dart';
import 'package:amar_dokan/features/suppliers/data/services/supplier_service.dart';

/// SupplierProvider - Supplier feature এর state management
///
/// এই provider:
/// - Supplier list hold করে (real-time stream থেকে)
/// - Search query manage করে
/// - Loading ও error state track করে
/// - CRUD operations wrap করে service এর উপর
class SupplierProvider extends ChangeNotifier {
  final SupplierService _service;

  SupplierProvider({SupplierService? service})
      : _service = service ?? SupplierService();

  // ============================================
  // State
  // ============================================

  List<SupplierModel> _suppliers = [];
  StreamSubscription<List<SupplierModel>>? _subscription;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // ============================================
  // Getters
  // ============================================

  /// সব suppliers (raw list, no filter)
  List<SupplierModel> get suppliers => _suppliers;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message (যদি থাকে)
  String? get errorMessage => _errorMessage;

  /// Current search query
  String get searchQuery => _searchQuery;

  /// Search ও sort করা supplier list (UI তে এটা ব্যবহার হবে)
  List<SupplierModel> get filteredSuppliers {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? List<SupplierModel>.from(_suppliers)
        : _suppliers.where((s) {
            return s.name.toLowerCase().contains(query) ||
                s.companyName.toLowerCase().contains(query) ||
                s.phone.toLowerCase().contains(query) ||
                (s.email != null && s.email!.toLowerCase().contains(query));
          }).toList();
    filtered.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return filtered;
  }

  /// Total supplier count
  int get totalSuppliers => _suppliers.length;

  /// Active supplier count
  int get activeSuppliersCount =>
      _suppliers.where((s) => s.isActive).length;

  /// Total spend across all suppliers
  double get totalSpend =>
      _suppliers.fold(0.0, (sum, s) => sum + s.totalPurchases);

  /// ID দিয়ে supplier খোঁজা
  SupplierModel? getSupplierById(String id) {
    try {
      return _suppliers.firstWhere((s) => s.id == id);
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

    _subscription = _service.getSuppliersStream().listen(
      (suppliers) {
        _suppliers = suppliers;
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

  /// নতুন supplier add করো
  /// Returns: created supplier এর ID
  Future<String> addSupplier(SupplierModel supplier) async {
    try {
      return await _service.addSupplier(supplier);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Supplier update করো
  Future<void> updateSupplier(SupplierModel supplier) async {
    try {
      await _service.updateSupplier(supplier);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Supplier delete করো
  Future<void> deleteSupplier(String supplierId) async {
    try {
      await _service.deleteSupplier(supplierId);
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
