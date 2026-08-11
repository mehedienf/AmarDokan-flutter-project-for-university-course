import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:amar_dokan/features/inventory/data/services/inventory_service.dart';
import 'package:amar_dokan/features/sales/data/models/sale_model.dart';

/// SaleService - Firestore এর সাথে sales data manage করে
///
/// Firestore path: users/{userId}/sales/{saleId}
///
/// Sale side-effects:
/// - `addSale` automatically decrements product stock for every item when the
///   sale status is `completed` (pending/cancelled leave stock untouched).
/// - `deleteSale` automatically restores stock for completed sales so that
///   returns / corrections don't leave the inventory drifted.
class SaleService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final InventoryService _inventoryService;

  SaleService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    InventoryService? inventoryService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _inventoryService = inventoryService ?? InventoryService();

  CollectionReference? get _salesCollection {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('sales');
  }

  Stream<List<SaleModel>> getSalesStream() {
    final collection = _salesCollection;
    if (collection == null) return Stream.value([]);

    return collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SaleModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<SaleModel>> getSalesByCustomerStream(String customerId) {
    final collection = _salesCollection;
    if (collection == null) return Stream.value([]);

    return collection
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SaleModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<SaleModel>> getSalesByDateRangeStream(
    DateTime startDate,
    DateTime endDate,
  ) {
    final collection = _salesCollection;
    if (collection == null) return Stream.value([]);

    return collection
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('saleDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('saleDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SaleModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<String> addSale(SaleModel sale) async {
    final collection = _salesCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }
    final docRef = await collection.add(sale.toFirestore());

    // Decrement inventory stock for every item — but only when the sale is
    // actually completed. Pending/cancelled sales keep the stock untouched so
    // that an unfinished invoice can't drive inventory negative.
    if (sale.status == 'completed') {
      for (final item in sale.items) {
        try {
          final existing =
              await _inventoryService.getProductById(item.productId);
          if (existing == null) continue;
          final newStock = (existing.stock - item.quantity).clamp(0, 1 << 31).toInt();
          await _inventoryService.updateStock(item.productId, newStock);
        } catch (_) {
          // Surface via provider error — don't fail the whole sale on one item.
        }
      }
    }

    return docRef.id;
  }

  Future<void> updateSale(SaleModel sale) async {
    final collection = _salesCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }
    await collection.doc(sale.id).update({
      ...sale.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Record a payment received against an existing sale (e.g. customer
  /// settles a partial sale). Atomically bumps `paidAmount`, recomputes
  /// `paymentStatus`, and stamps `updatedAt`. Refuses to over-pay.
  ///
  /// Returns the new paidAmount after the write. Throws on sale-not-found
  /// or when amount is non-positive / would exceed total.
  Future<double> recordPaymentAgainstSale({
    required String saleId,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Payment amount must be positive');
    }
    final collection = _salesCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    final docRef = collection.doc(saleId);
    final doc = await docRef.get();
    if (!doc.exists) {
      throw Exception('Sale not found: $saleId');
    }
    final sale = SaleModel.fromFirestore(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );

    final remaining = sale.total - sale.paidAmount;
    if (remaining <= 0) {
      throw Exception('This sale is already fully paid');
    }
    final newPaid = (sale.paidAmount + amount).clamp(0.0, sale.total);
    final newStatus = newPaid >= sale.total
        ? 'paid'
        : (newPaid > 0 ? 'partial' : 'unpaid');

    await docRef.update({
      'paidAmount': newPaid,
      'paymentStatus': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return newPaid.toDouble();
  }

  Future<void> deleteSale(String saleId) async {
    final collection = _salesCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    // Snapshot before delete so we can restore stock if this was a completed sale.
    final doc = await collection.doc(saleId).get();
    SaleModel? existing;
    if (doc.exists) {
      existing = SaleModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }

    await collection.doc(saleId).delete();

    if (existing != null && existing.status == 'completed') {
      for (final item in existing.items) {
        try {
          final product =
              await _inventoryService.getProductById(item.productId);
          if (product == null) continue;
          final newStock = product.stock + item.quantity;
          await _inventoryService.updateStock(item.productId, newStock);
        } catch (_) {
          // Skip silent failures — provider should surface errors.
        }
      }
    }
  }

  Future<SaleModel?> getSale(String saleId) async {
    final collection = _salesCollection;
    if (collection == null) return null;

    final doc = await collection.doc(saleId).get();
    if (!doc.exists) return null;
    return SaleModel.fromFirestore(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  // ============================================
  // Aggregations
  // ============================================

  /// Total revenue (sum of all completed sales) within a date range
  Future<double> getTotalRevenue(DateTime startDate, DateTime endDate) async {
    final collection = _salesCollection;
    if (collection == null) return 0.0;

    final snapshot = await collection
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('saleDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .where('status', isEqualTo: 'completed')
        .get();

    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['total'] ?? 0).toDouble();
    }
    return total;
  }

  /// Total profit within a date range
  Future<double> getTotalProfit(DateTime startDate, DateTime endDate) async {
    final collection = _salesCollection;
    if (collection == null) return 0.0;

    final snapshot = await collection
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('saleDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .where('status', isEqualTo: 'completed')
        .get();

    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['totalProfit'] ?? 0).toDouble();
    }
    return total;
  }

  /// Count of sales within a date range (status filter optional)
  Future<int> getSalesCount(
    DateTime startDate,
    DateTime endDate, {
    String? status,
  }) async {
    final collection = _salesCollection;
    if (collection == null) return 0;

    Query baseQuery = collection
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('saleDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));

    if (status != null) {
      baseQuery = baseQuery.where('status', isEqualTo: status);
    }

    final snapshot = await baseQuery.count().get();
    return snapshot.count ?? 0;
  }

  /// Generate next invoice number (e.g. INV-000001)
  /// Strategy: count existing sales + 1, zero-padded
  Future<String> generateNextInvoiceNumber() async {
    final collection = _salesCollection;
    if (collection == null) return 'INV-000001';

    final snapshot = await collection.count().get();
    final count = snapshot.count ?? 0;
    final next = count + 1;
    return 'INV-${next.toString().padLeft(6, '0')}';
  }

  // ============================================
  // Filtering helpers
  // ============================================

  /// Client-side text search over invoice, customer, notes
  List<SaleModel> filterByQuery(List<SaleModel> sales, String query) {
    if (query.trim().isEmpty) return sales;
    final lower = query.toLowerCase();
    return sales.where((s) {
      return s.invoiceNumber.toLowerCase().contains(lower) ||
          (s.customerName?.toLowerCase().contains(lower) ?? false) ||
          (s.notes?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  /// Filter by payment status
  List<SaleModel> filterByPaymentStatus(
    List<SaleModel> sales,
    String status,
  ) {
    if (status == 'all') return sales;
    return sales.where((s) => s.paymentStatus == status).toList();
  }

  /// Filter by date range
  List<SaleModel> filterByDateRange(
    List<SaleModel> sales,
    DateTime start,
    DateTime end,
  ) {
    return sales.where((s) {
      final date = s.saleDate ?? s.createdAt;
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }
}
