import 'dart:async';
import 'package:flutter/material.dart';

import 'package:amar_dokan/features/inventory/data/models/product_model.dart';
import 'package:amar_dokan/features/inventory/data/services/inventory_service.dart';

/// Inventory Provider - Inventory feature এর state management
///
/// এই provider:
/// - Products এর list hold করে
/// - Firestore stream listen করে
/// - UI কে notify করে যখন data পরিবর্তন হয়
class InventoryProvider extends ChangeNotifier {
  // Service instance
  final InventoryService _service = InventoryService();

  // State variables
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Stream subscription
  StreamSubscription<List<ProductModel>>? _subscription;

  // ============================================
  // Getters
  // ============================================

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtered getters
  int get totalProducts => _products.length;
  int get totalStock => _products.fold(0, (sum, p) => sum + p.stock);
  int get lowStockCount => _products.where((p) => p.isLowStock).length;
  int get outOfStockCount => _products.where((p) => p.isOutOfStock).length;

  double get totalStockValue =>
      _products.fold(0, (sum, p) => sum + p.totalStockValue);

  double get totalPotentialProfit =>
      _products.fold(0, (sum, p) => sum + p.totalPotentialProfit);

  List<ProductModel> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();

  List<ProductModel> get outOfStockProducts =>
      _products.where((p) => p.isOutOfStock).toList();

  // ============================================
  // Firestore Stream Management
  // ============================================

  /// Firestore stream শুরু করে products listen করে
  /// যখনই database এ কিছু পরিবর্তন হবে, _products update হবে
  void startListening() {
    _subscription?.cancel(); // আগের subscription বন্ধ

    _setLoading(true);

    _subscription = _service.getProductsStream().listen(
      (products) {
        _products = products;
        _errorMessage = null;
        _setLoading(false);
      },
      onError: (error) {
        _errorMessage = error.toString();
        _setLoading(false);
      },
    );
  }

  /// Stream listening বন্ধ করে
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Provider dispose হলে stream বন্ধ করা important
  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  // ============================================
  // CRUD Operations
  // ============================================

  /// নতুন product add করে
  Future<bool> addProduct(ProductModel product) async {
    try {
      _setLoading(true);
      await _service.addProduct(product);
      // Stream automatic update দেবে, কিন্তু আমরা notify করি
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Product update করে
  Future<bool> updateProduct(ProductModel product) async {
    try {
      _setLoading(true);
      await _service.updateProduct(product);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Product delete করে
  Future<bool> deleteProduct(String productId) async {
    try {
      _setLoading(true);
      await _service.deleteProduct(productId);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Product search করে
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      return await _service.searchProducts(query);
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  // ============================================
  // Helper Methods
  // ============================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Error message clear করে
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// ID দিয়ে product খোঁজে
  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}