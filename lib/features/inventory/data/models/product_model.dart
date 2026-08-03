import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amar_dokan/features/inventory/data/models/product_category.dart';

/// Product Model - Firestore এর সাথে কাজ করার জন্য design করা
///
/// এই model এর প্রতিটি field এর purpose:
/// - id: Firestore document ID
/// - name: Product এর নাম
/// - sku: Stock Keeping Unit (unique identifier, barcode এর মতো)
/// - category: Product এর category (enum)
/// - purchasePrice: কেনা দাম (profit calculation এ লাগবে)
/// - sellingPrice: বেচা দাম (customer কে যে দামে বিক্রি হবে)
/// - stock: Current stock quantity
/// - lowStockThreshold: কত quantity এর নিচে গেলে low stock alert দেবে
/// - description: Product এর বিস্তারিত (optional)
/// - imageUrl: Product image এর URL (optional)
/// - createdAt: কখন add হয়েছে
/// - updatedAt: কখন শেষ update হয়েছে
class ProductModel {
  final String id;
  final String name;
  final String sku;
  final ProductCategory category;
  final double purchasePrice;
  final double sellingPrice;
  final int stock;
  final int lowStockThreshold;
  final String? description;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stock,
    required this.lowStockThreshold,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.imageUrl,
  });

  // ============================================
  // Business Logic (Getters)
  // ============================================

  /// Stock আছে কিনা
  bool get isInStock => stock > 0;

  /// Stock low কিনা (threshold এর নিচে কিন্তু শূন্য এর উপরে)
  bool get isLowStock => stock > 0 && stock <= lowStockThreshold;

  /// Stock শেষ হয়ে গেছে কিনা
  bool get isOutOfStock => stock == 0;

  /// একটি unit এর profit
  double get profitPerUnit => sellingPrice - purchasePrice;

  /// Total profit (stock * profit per unit)
  double get totalPotentialProfit => stock * profitPerUnit;

  /// Total stock value (purchase price অনুসারে)
  double get totalStockValue => stock * purchasePrice;

  /// Profit margin percentage
  double get profitMarginPercentage {
    if (purchasePrice == 0) return 0;
    return (profitPerUnit / purchasePrice) * 100;
  }

  /// Profit margin percentage display string (e.g., "25%")
  String get profitMarginDisplay {
    return '${profitMarginPercentage.toStringAsFixed(1)}%';
  }

  /// Stock status display string
  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  // ============================================
  // Firestore Serialization
  // ============================================

  /// Firestore document থেকে ProductModel বানাও
  /// Firestore এ data `Map<String, dynamic>` হিসেবে থাকে
  factory ProductModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return ProductModel(
      id: documentId,
      // String fields — null হলে empty string দিই
      name: data['name'] ?? '',
      sku: data['sku'] ?? '',
      category: ProductCategory.fromString(data['category'] as String?),

      // Number fields — Firestore এ number stored হয়
      purchasePrice: (data['purchasePrice'] ?? 0).toDouble(),
      sellingPrice: (data['sellingPrice'] ?? 0).toDouble(),
      stock: (data['stock'] ?? 0).toInt(),
      lowStockThreshold: (data['lowStockThreshold'] ?? 5).toInt(),

      // Optional fields
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?,

      // Timestamp fields — Firestore এ Timestamp হিসেবে store হয়
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// ProductModel কে Firestore document এ save করার জন্য Map এ convert
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'sku': sku,
      'category': category.name, // Enum কে String এ convert
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'stock': stock,
      'lowStockThreshold': lowStockThreshold,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ============================================
  // Copy & Update Methods
  // ============================================

  /// Product এর copy return করে, কিছু field change করে
  /// এটা Provider এ update করার সময় কাজে লাগবে
  ProductModel copyWith({
    String? id,
    String? name,
    String? sku,
    ProductCategory? category,
    double? purchasePrice,
    double? sellingPrice,
    int? stock,
    int? lowStockThreshold,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============================================
  // Display Helpers
  // ============================================

  /// Debug এ print করার সময় সুন্দর দেখাবে
  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, stock: $stock, price: $sellingPrice)';
  }

  /// দুটি ProductModel সমান কিনা
  /// Provider এ update detect করতে কাজে লাগবে
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel &&
        other.id == id &&
        other.name == name &&
        other.sku == sku &&
        other.category == category &&
        other.purchasePrice == purchasePrice &&
        other.sellingPrice == sellingPrice &&
        other.stock == stock &&
        other.lowStockThreshold == lowStockThreshold &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      sku,
      category,
      purchasePrice,
      sellingPrice,
      stock,
      lowStockThreshold,
      description,
      imageUrl,
      createdAt,
      updatedAt,
    );
  }
}