import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:amar_dokan/features/inventory/data/services/inventory_service.dart';
import 'package:amar_dokan/features/purchase/data/models/purchase_model.dart';

/// PurchaseService - Firestore এর সাথে purchases data manage করে।
///
/// Firestore path: users/{userId}/purchases/{purchaseId}
///
/// Purchase side-effects:
/// - `addPurchase` automatically increments product stock for every item
///   and updates the product's `purchasePrice` to the latest unit cost.
/// - `deletePurchase` automatically decrements product stock for every item.
class PurchaseService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final InventoryService _inventoryService;

  PurchaseService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    InventoryService? inventoryService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _inventoryService = inventoryService ?? InventoryService();

  CollectionReference? get _purchasesCollection {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('purchases');
  }

  // ============================================
  // Streams
  // ============================================

  Stream<List<PurchaseModel>> getPurchasesStream() {
    final collection = _purchasesCollection;
    if (collection == null) return Stream.value([]);

    return collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PurchaseModel.fromFirestore(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<PurchaseModel>> getPurchasesBySupplierStream(String supplierId) {
    final collection = _purchasesCollection;
    if (collection == null) return Stream.value([]);

    return collection
        .where('supplierId', isEqualTo: supplierId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PurchaseModel.fromFirestore(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<PurchaseModel>> getPurchasesByDateRangeStream(
    DateTime startDate,
    DateTime endDate,
  ) {
    final collection = _purchasesCollection;
    if (collection == null) return Stream.value([]);

    return collection
        .where('purchaseDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('purchaseDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PurchaseModel.fromFirestore(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // ============================================
  // CRUD
  // ============================================

  /// Add a new purchase AND increment product stock for each item.
  Future<String> addPurchase(PurchaseModel purchase) async {
    final collection = _purchasesCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    final docRef = await collection.add(purchase.toFirestore());

    // Stock-in + price refresh for every item.
    for (final item in purchase.items) {
      try {
        final existing = await _inventoryService.getProductById(item.productId);
        if (existing == null) continue;
        final newStock = existing.stock + item.quantity;
        // Use updateStock for the atomic stock change, then patch purchasePrice.
        await _inventoryService.updateStock(item.productId, newStock);
        await _inventoryService.updateProduct(
          existing.copyWith(
            purchasePrice: item.unitPrice,
            sellingPrice: item.unitSellingPrice > 0
                ? item.unitSellingPrice
                : existing.sellingPrice,
          ),
        );
      } catch (_) {
        // Continue processing other items; surface via provider error.
      }
    }

    return docRef.id;
  }

  /// Update an existing purchase. Stock adjustment is NOT applied automatically
  /// (avoids drift). Caller should manage stock corrections separately if needed.
  Future<void> updatePurchase(PurchaseModel purchase) async {
    final collection = _purchasesCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }
    await collection.doc(purchase.id).update({
      ...purchase.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a purchase AND decrement product stock for each item.
  Future<void> deletePurchase(String purchaseId) async {
    final collection = _purchasesCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    // Snapshot existing items first so we can decrement after deletion.
    final doc = await collection.doc(purchaseId).get();
    PurchaseModel? existing;
    if (doc.exists) {
      existing = PurchaseModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }

    await collection.doc(purchaseId).delete();

    if (existing != null) {
      for (final item in existing.items) {
        try {
          final product =
              await _inventoryService.getProductById(item.productId);
          if (product == null) continue;
          final newStock =
              (product.stock - item.quantity).clamp(0, 1 << 31).toInt();
          await _inventoryService.updateStock(item.productId, newStock);
        } catch (_) {
          // Skip silent failures — provider should surface errors.
        }
      }
    }
  }

  Future<PurchaseModel?> getPurchase(String purchaseId) async {
    final collection = _purchasesCollection;
    if (collection == null) return null;

    final doc = await collection.doc(purchaseId).get();
    if (!doc.exists) return null;
    return PurchaseModel.fromFirestore(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  // ============================================
  // Aggregations
  // ============================================

  /// Total amount spent on purchases within a date range (status filter optional).
  Future<double> getTotalSpent(
    DateTime startDate,
    DateTime endDate, {
    String? status,
  }) async {
    final collection = _purchasesCollection;
    if (collection == null) return 0.0;

    Query baseQuery = collection
        .where('purchaseDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('purchaseDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));

    if (status != null) {
      baseQuery = baseQuery.where('status', isEqualTo: status);
    }

    final snapshot = await baseQuery.get();
    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['total'] ?? 0).toDouble();
    }
    return total;
  }

  /// Total outstanding amount owed to suppliers (balance > 0).
  Future<double> getOutstandingAmount() async {
    final collection = _purchasesCollection;
    if (collection == null) return 0.0;

    final snapshot = await collection.get();
    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final t = (data['total'] ?? 0).toDouble();
      final p = (data['paidAmount'] ?? 0).toDouble();
      final due = (t - p).clamp(0, double.infinity).toDouble();
      total += due;
    }
    return total;
  }

  /// Count of purchases within a date range (status filter optional).
  Future<int> getPurchasesCount(
    DateTime startDate,
    DateTime endDate, {
    String? status,
  }) async {
    final collection = _purchasesCollection;
    if (collection == null) return 0;

    Query baseQuery = collection
        .where('purchaseDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('purchaseDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));

    if (status != null) {
      baseQuery = baseQuery.where('status', isEqualTo: status);
    }

    final snapshot = await baseQuery.count().get();
    return snapshot.count ?? 0;
  }

  /// Generate next invoice number (e.g. PUR-000001).
  Future<String> generateNextInvoiceNumber() async {
    final collection = _purchasesCollection;
    if (collection == null) return 'PUR-000001';

    final snapshot = await collection.count().get();
    final count = snapshot.count ?? 0;
    final next = count + 1;
    return 'PUR-${next.toString().padLeft(6, '0')}';
  }

  // ============================================
  // Client-side filter helpers
  // ============================================

  List<PurchaseModel> filterByQuery(
    List<PurchaseModel> purchases,
    String query,
  ) {
    if (query.trim().isEmpty) return purchases;
    final lower = query.toLowerCase();
    return purchases.where((p) {
      return p.invoiceNumber.toLowerCase().contains(lower) ||
          (p.supplierName?.toLowerCase().contains(lower) ?? false) ||
          (p.supplierInvoice?.toLowerCase().contains(lower) ?? false) ||
          (p.notes?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  List<PurchaseModel> filterByStatus(
    List<PurchaseModel> purchases,
    String status,
  ) {
    if (status == 'all') return purchases;
    return purchases.where((p) => p.status == status).toList();
  }

  List<PurchaseModel> filterByPaymentStatus(
    List<PurchaseModel> purchases,
    String paymentStatus,
  ) {
    if (paymentStatus == 'all') return purchases;
    return purchases.where((p) => p.paymentStatus == paymentStatus).toList();
  }

  List<PurchaseModel> filterByDateRange(
    List<PurchaseModel> purchases,
    DateTime start,
    DateTime end,
  ) {
    return purchases.where((p) {
      final date = p.purchaseDate ?? p.createdAt;
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }
}