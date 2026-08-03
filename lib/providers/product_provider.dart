import 'package:flutter/material.dart';
import '../features/inventory/data/models/product_model.dart';

/// Product Provider - State management for products
/// এখন temporary local list, পরে Firestore এ migrate হবে
class ProductProvider extends ChangeNotifier {
  final List<ProductModel> _products = [];

  List<ProductModel> get products => _products;

  int get productCount => _products.length;

  void addProduct(ProductModel product) {
    _products.add(product);
    notifyListeners();
  }

  void removeProduct(int index) {
    _products.removeAt(index);
    notifyListeners();
  }

  void updateProduct(int index, ProductModel product) {
    _products[index] = product;
    notifyListeners();
  }
}