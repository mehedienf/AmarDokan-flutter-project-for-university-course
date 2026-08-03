import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:amar_dokan/features/sales/data/models/sale_model.dart';

/// SaleService - Firestore এর সাথে sales data manage করে
///
/// Firestore path: users/{userId}/sales/{saleId}
class SaleService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SaleService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

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

  Future<void> deleteSale(String saleId) async {
    final collection = _salesCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }
    await collection.doc(saleId).delete();
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
