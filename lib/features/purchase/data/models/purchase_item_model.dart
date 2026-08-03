/// PurchaseItem Model - represents one line item in a purchase.
///
/// Multiple items can exist per purchase (cart-style).
/// Since product details can change over time (rename, price change),
/// we keep a snapshot copy of the product at purchase time.
class PurchaseItemModel {
  // Product reference
  final String productId;

  // Product snapshot — what the product looked like at time of purchase
  final String productName;
  final String? sku;

  // Quantities & pricing
  final int quantity;
  final double unitPrice; // Purchase (cost) price per unit at time of purchase
  final double unitSellingPrice; // Selling price at the time (for margin context)
  final double discount; // Per-item discount amount

  const PurchaseItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.unitSellingPrice = 0.0,
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

  /// Expected profit contribution if sold at current selling price
  /// total - cost_of_goods_sold
  double get expectedProfit =>
      total - (quantity * unitPrice) + (quantity * (unitSellingPrice - unitPrice));

  /// Future profit if all units sold (selling - cost) × quantity
  double get futureProfit =>
      quantity * (unitSellingPrice - unitPrice);

  // ============================================
  // Firestore Serialization
  // ============================================

  factory PurchaseItemModel.fromFirestore(Map<String, dynamic> data) {
    return PurchaseItemModel(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      sku: data['sku'] as String?,
      quantity: (data['quantity'] ?? 0).toInt(),
      unitPrice: (data['unitPrice'] ?? 0).toDouble(),
      unitSellingPrice: (data['unitSellingPrice'] ?? 0).toDouble(),
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
      'unitSellingPrice': unitSellingPrice,
      'discount': discount,
    };
  }

  // ============================================
  // Copy & Equality
  // ============================================

  PurchaseItemModel copyWith({
    String? productId,
    String? productName,
    String? sku,
    int? quantity,
    double? unitPrice,
    double? unitSellingPrice,
    double? discount,
  }) {
    return PurchaseItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unitSellingPrice: unitSellingPrice ?? this.unitSellingPrice,
      discount: discount ?? this.discount,
    );
  }

  @override
  String toString() {
    return 'PurchaseItemModel(productId: $productId, name: $productName, qty: $quantity, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseItemModel &&
        other.productId == productId &&
        other.productName == productName &&
        other.sku == sku &&
        other.quantity == quantity &&
        other.unitPrice == unitPrice &&
        other.unitSellingPrice == unitSellingPrice &&
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
      unitSellingPrice,
      discount,
    );
  }
}
