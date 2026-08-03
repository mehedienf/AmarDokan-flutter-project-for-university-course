/// SaleItem Model - represents one line item in a sale.
///
/// Multiple items can exist per sale (cart-style).
/// Since product details can change over time (rename, price change),
/// we keep a snapshot copy of the product at sale time.
class SaleItemModel {
  // Product reference
  final String productId;

  // Product snapshot — what the product looked like at time of sale
  final String productName;
  final String? sku;

  // Quantities & pricing
  final int quantity;
  final double unitPrice; // Selling price per unit at time of sale
  final double unitCost; // Cost price per unit at time of sale (profit tracking)
  final double discount; // Per-item discount amount

  const SaleItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    this.sku,
    this.discount = 0.0,
  });

  // ============================================
  // Calculated getters
  // ============================================

  /// Subtotal before discount (quantity × unit price)
  double get subtotal => quantity * unitPrice;

  /// Final amount for this line item (after discount)
  double get total => (subtotal - discount).clamp(0, double.infinity);

  /// Profit contribution of this line item
  /// total - cost_of_goods_sold
  /// cost = quantity × unitCost
  double get profit => total - (quantity * unitCost);

  /// Profit margin percentage (0-100)
  double get profitMargin =>
      total > 0 ? (profit / total) * 100 : 0.0;

  // ============================================
  // Firestore Serialization
  // ============================================

  factory SaleItemModel.fromFirestore(Map<String, dynamic> data) {
    return SaleItemModel(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      sku: data['sku'] as String?,
      quantity: (data['quantity'] ?? 0).toInt(),
      unitPrice: (data['unitPrice'] ?? 0).toDouble(),
      unitCost: (data['unitCost'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unitCost': unitCost,
      'discount': discount,
    };
  }

  // ============================================
  // Copy & Equality
  // ============================================

  SaleItemModel copyWith({
    String? productId,
    String? productName,
    String? sku,
    int? quantity,
    double? unitPrice,
    double? unitCost,
    double? discount,
  }) {
    return SaleItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCost: unitCost ?? this.unitCost,
      discount: discount ?? this.discount,
    );
  }

  @override
  String toString() {
    return 'SaleItemModel(productId: $productId, name: $productName, qty: $quantity, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaleItemModel &&
        other.productId == productId &&
        other.productName == productName &&
        other.sku == sku &&
        other.quantity == quantity &&
        other.unitPrice == unitPrice &&
        other.unitCost == unitCost &&
        other.discount == discount;
  }

  @override
  int get hashCode {
    return Object.hash(
      productId,
      productName,
      sku,
      quantity,
      unitPrice,
      unitCost,
      discount,
    );
  }
}
