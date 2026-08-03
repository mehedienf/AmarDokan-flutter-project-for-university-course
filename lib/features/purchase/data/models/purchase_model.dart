import 'package:cloud_firestore/cloud_firestore.dart';

import 'purchase_item_model.dart';

/// Purchase Model - represents a purchase transaction (supplier side).
class PurchaseModel {
  final String id;
  final String invoiceNumber;
  final String? supplierId;
  final String? supplierName;
  final String? supplierInvoice;
  final List<PurchaseItemModel> items;
  final double subtotal;
  final double itemDiscount;
  final double extraDiscount;
  final double tax;
  final double shippingCost;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final double paidAmount;
  final double dueAmount;
  final String status;
  final String? notes;
  final DateTime? purchaseDate;
  final DateTime? expectedDeliveryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PurchaseModel({
    required this.id,
    required this.invoiceNumber,
    required this.items,
    required this.subtotal,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.supplierId,
    this.supplierName,
    this.supplierInvoice,
    this.itemDiscount = 0.0,
    this.extraDiscount = 0.0,
    this.tax = 0.0,
    this.shippingCost = 0.0,
    this.paidAmount = 0.0,
    this.dueAmount = 0.0,
    this.notes,
    this.purchaseDate,
    this.expectedDeliveryDate,
  });

  // ============================================
  // Calculated getters
  // ============================================

  /// Outstanding balance still owed to supplier.
  double get balance => (total - paidAmount).clamp(0, double.infinity);

  bool get isPaid => paymentStatus == 'paid' || paidAmount >= total;
  bool get isPartial => paymentStatus == 'partial' && paidAmount > 0;
  bool get isUnpaid => paymentStatus == 'unpaid' || paidAmount <= 0;

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';

  int get totalItems =>
      items.fold(0, (acc, item) => acc + item.quantity);
  int get uniqueProducts => items.length;

  /// Sum of expected profit from all line items (selling - cost × qty).
  double get totalExpectedProfit =>
      items.fold(0.0, (acc, item) => acc + item.futureProfit);

  bool get hasSupplier =>
      supplierId != null && supplierId!.isNotEmpty;
  bool get hasSupplierInvoice =>
      supplierInvoice != null && supplierInvoice!.isNotEmpty;
  bool get hasNotes => notes != null && notes!.isNotEmpty;
  bool get hasDiscount => (itemDiscount + extraDiscount) > 0;
  bool get hasShipping => shippingCost > 0;
  bool get hasExpectedDelivery => expectedDeliveryDate != null;

  String get displayPaymentMethod {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'mobile':
      case 'mobile_banking':
      case 'bkash':
      case 'nagad':
        return 'Mobile Banking';
      case 'bank':
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cheque':
      case 'check':
        return 'Cheque';
      case 'credit':
        return 'Credit';
      default:
        return paymentMethod;
    }
  }

  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  // ============================================
  // Firestore Serialization
  // ============================================

  factory PurchaseModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    final itemsRaw = data['items'] as List<dynamic>? ?? const [];
    final items = itemsRaw
        .map((e) =>
            PurchaseItemModel.fromFirestore(e as Map<String, dynamic>))
        .toList();

    return PurchaseModel(
      id: documentId,
      invoiceNumber: data['invoiceNumber'] ?? '',
      supplierId: data['supplierId'] as String?,
      supplierName: data['supplierName'] as String?,
      supplierInvoice: data['supplierInvoice'] as String?,
      items: items,
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      itemDiscount: (data['itemDiscount'] ?? 0).toDouble(),
      extraDiscount: (data['extraDiscount'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      shippingCost: (data['shippingCost'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'cash',
      paymentStatus: data['paymentStatus'] ?? 'paid',
      paidAmount: (data['paidAmount'] ?? 0).toDouble(),
      dueAmount: (data['dueAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'completed',
      notes: data['notes'] as String?,
      purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate(),
      expectedDeliveryDate:
          (data['expectedDeliveryDate'] as Timestamp?)?.toDate(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'invoiceNumber': invoiceNumber,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'supplierInvoice': supplierInvoice,
      'items': items.map((i) => i.toFirestore()).toList(),
      'subtotal': subtotal,
      'itemDiscount': itemDiscount,
      'extraDiscount': extraDiscount,
      'tax': tax,
      'shippingCost': shippingCost,
      'total': total,
      'totalExpectedProfit': totalExpectedProfit,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paidAmount': paidAmount,
      'dueAmount': dueAmount,
      'status': status,
      'notes': notes,
      'purchaseDate': purchaseDate != null
          ? Timestamp.fromDate(purchaseDate!)
          : Timestamp.fromDate(createdAt),
      'expectedDeliveryDate': expectedDeliveryDate != null
          ? Timestamp.fromDate(expectedDeliveryDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ============================================
  // Copy & Equality
  // ============================================

  PurchaseModel copyWith({
    String? id,
    String? invoiceNumber,
    String? supplierId,
    String? supplierName,
    String? supplierInvoice,
    List<PurchaseItemModel>? items,
    double? subtotal,
    double? itemDiscount,
    double? extraDiscount,
    double? tax,
    double? shippingCost,
    double? total,
    String? paymentMethod,
    String? paymentStatus,
    double? paidAmount,
    double? dueAmount,
    String? status,
    String? notes,
    DateTime? purchaseDate,
    DateTime? expectedDeliveryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierInvoice: supplierInvoice ?? this.supplierInvoice,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      itemDiscount: itemDiscount ?? this.itemDiscount,
      extraDiscount: extraDiscount ?? this.extraDiscount,
      tax: tax ?? this.tax,
      shippingCost: shippingCost ?? this.shippingCost,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expectedDeliveryDate:
          expectedDeliveryDate ?? this.expectedDeliveryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PurchaseModel(id: $id, invoice: $invoiceNumber, total: $total, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseModel &&
        other.id == id &&
        other.invoiceNumber == invoiceNumber &&
        other.supplierId == supplierId &&
        other.supplierName == supplierName &&
        other.supplierInvoice == supplierInvoice &&
        other.subtotal == subtotal &&
        other.itemDiscount == itemDiscount &&
        other.extraDiscount == extraDiscount &&
        other.tax == tax &&
        other.shippingCost == shippingCost &&
        other.total == total &&
        other.paymentMethod == paymentMethod &&
        other.paymentStatus == paymentStatus &&
        other.paidAmount == paidAmount &&
        other.dueAmount == dueAmount &&
        other.status == status &&
        other.notes == notes &&
        other.purchaseDate == purchaseDate &&
        other.expectedDeliveryDate == expectedDeliveryDate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      invoiceNumber,
      supplierId,
      supplierName,
      supplierInvoice,
      subtotal,
      itemDiscount,
      extraDiscount,
      tax,
      shippingCost,
      total,
      paymentMethod,
      paymentStatus,
      paidAmount,
      dueAmount,
      status,
      notes,
      purchaseDate,
      expectedDeliveryDate,
      createdAt,
      // updatedAt omitted to stay within Object.hash's 20-arg limit
    );
  }
}
