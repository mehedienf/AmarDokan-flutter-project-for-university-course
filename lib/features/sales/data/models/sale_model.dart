import 'package:cloud_firestore/cloud_firestore.dart';

import 'sale_item_model.dart';

/// Sale Model - represents a sales transaction.
class SaleModel {
  final String id;
  final String invoiceNumber;
  final String? customerId;
  final String? customerName;
  final List<SaleItemModel> items;
  final double subtotal;
  final double itemDiscount;
  final double extraDiscount;
  final double tax;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final double paidAmount;
  final double changeAmount;
  final String status;
  final String? notes;
  final DateTime? saleDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SaleModel({
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
    this.customerId,
    this.customerName,
    this.itemDiscount = 0.0,
    this.extraDiscount = 0.0,
    this.tax = 0.0,
    this.paidAmount = 0.0,
    this.changeAmount = 0.0,
    this.notes,
    this.saleDate,
  });

  double get balance => (total - paidAmount).clamp(0, double.infinity);
  bool get isPaid => paymentStatus == 'paid' || paidAmount >= total;
  bool get isPartial => paymentStatus == 'partial' && paidAmount > 0;
  bool get isUnpaid => paymentStatus == 'unpaid' || paidAmount <= 0;
  bool get isCompleted => status == 'completed';
  int get totalItems => items.fold(0, (total, item) => total + item.quantity);
  int get uniqueProducts => items.length;
  double get totalProfit => items.fold(0.0, (total, item) => total + item.profit);
  bool get hasCustomer => customerId != null && customerId!.isNotEmpty;
  bool get hasNotes => notes != null && notes!.isNotEmpty;
  bool get hasDiscount => (itemDiscount + extraDiscount) > 0;

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
      case 'credit':
        return 'Credit';
      default:
        return paymentMethod;
    }
  }

  factory SaleModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    final itemsRaw = data['items'] as List<dynamic>? ?? const [];
    final items = itemsRaw
        .map((e) => SaleItemModel.fromFirestore(e as Map<String, dynamic>))
        .toList();

    return SaleModel(
      id: documentId,
      invoiceNumber: data['invoiceNumber'] ?? '',
      customerId: data['customerId'] as String?,
      customerName: data['customerName'] as String?,
      items: items,
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      itemDiscount: (data['itemDiscount'] ?? 0).toDouble(),
      extraDiscount: (data['extraDiscount'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'cash',
      paymentStatus: data['paymentStatus'] ?? 'paid',
      paidAmount: (data['paidAmount'] ?? 0).toDouble(),
      changeAmount: (data['changeAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'completed',
      notes: data['notes'] as String?,
      saleDate: (data['saleDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((i) => i.toFirestore()).toList(),
      'subtotal': subtotal,
      'itemDiscount': itemDiscount,
      'extraDiscount': extraDiscount,
      'tax': tax,
      'total': total,
      'totalProfit': totalProfit,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paidAmount': paidAmount,
      'changeAmount': changeAmount,
      'status': status,
      'notes': notes,
      'saleDate': saleDate != null
          ? Timestamp.fromDate(saleDate!)
          : Timestamp.fromDate(createdAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SaleModel copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    List<SaleItemModel>? items,
    double? subtotal,
    double? itemDiscount,
    double? extraDiscount,
    double? tax,
    double? total,
    String? paymentMethod,
    String? paymentStatus,
    double? paidAmount,
    double? changeAmount,
    String? status,
    String? notes,
    DateTime? saleDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SaleModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      itemDiscount: itemDiscount ?? this.itemDiscount,
      extraDiscount: extraDiscount ?? this.extraDiscount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      saleDate: saleDate ?? this.saleDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SaleModel(id: $id, invoice: $invoiceNumber, total: $total, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaleModel &&
        other.id == id &&
        other.invoiceNumber == invoiceNumber &&
        other.customerId == customerId &&
        other.customerName == customerName &&
        other.subtotal == subtotal &&
        other.itemDiscount == itemDiscount &&
        other.extraDiscount == extraDiscount &&
        other.tax == tax &&
        other.total == total &&
        other.paymentMethod == paymentMethod &&
        other.paymentStatus == paymentStatus &&
        other.paidAmount == paidAmount &&
        other.changeAmount == changeAmount &&
        other.status == status &&
        other.notes == notes &&
        other.saleDate == saleDate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      invoiceNumber,
      customerId,
      customerName,
      subtotal,
      itemDiscount,
      extraDiscount,
      tax,
      total,
      paymentMethod,
      paymentStatus,
      paidAmount,
      changeAmount,
      status,
      notes,
      saleDate,
      createdAt,
      updatedAt,
    );
  }
}
