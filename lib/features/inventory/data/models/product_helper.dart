import 'package:amar_dokan/features/inventory/data/models/product_model.dart';
import 'package:amar_dokan/features/inventory/data/models/product_category.dart';

/// Product Helper - নতুন product বানানোর জন্য
class ProductHelper {
  ProductHelper._();

  /// নতুন empty product template
  /// Add Product screen এ initial value হিসেবে ব্যবহার হবে
  static ProductModel empty() {
    return ProductModel(
      id: '',
      name: '',
      sku: '',
      category: ProductCategory.other,
      purchasePrice: 0.0,
      sellingPrice: 0.0,
      stock: 0,
      lowStockThreshold: 5,
      description: null,
      imageUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Validation helpers
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Product name is required';
    }
    if (value.trim().length > 100) {
      return 'Product name too long (max 100 characters)';
    }
    return null;
  }

  static String? validateSku(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'SKU is required';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value);
    if (price == null) {
      return 'Enter a valid number';
    }
    if (price <= 0) {
      return 'Price must be greater than 0';
    }
    return null;
  }

  static String? validateStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stock is required';
    }
    final stock = int.tryParse(value);
    if (stock == null) {
      return 'Enter a valid number';
    }
    if (stock < 0) {
      return 'Stock cannot be negative';
    }
    return null;
  }
}
