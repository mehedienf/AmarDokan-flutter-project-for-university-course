import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:amar_dokan/features/suppliers/data/models/supplier_model.dart';

/// SupplierService - Firestore এর সাথে supplier data manage করে
///
/// Firestore path: users/{userId}/suppliers/{supplierId}
///
/// এই service এর কাজ:
/// - Real-time stream দিয়ে supplier list পাওয়া
/// - Supplier add/update/delete করা
/// - Search query দিয়ে filter করা
class SupplierService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SupplierService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Current user এর suppliers collection reference
  CollectionReference? get _suppliersCollection {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('suppliers');
  }

  /// Real-time stream of all suppliers (newest first)
  /// Authenticated user না থাকলে empty stream দেয়
  Stream<List<SupplierModel>> getSuppliersStream() {
    final collection = _suppliersCollection;
    if (collection == null) return Stream.value([]);

    return collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SupplierModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// নতুন supplier add করো
  Future<String> addSupplier(SupplierModel supplier) async {
    final collection = _suppliersCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }
    final docRef = await collection.add(supplier.toFirestore());
    return docRef.id;
  }

  /// Existing supplier update করো
  Future<void> updateSupplier(SupplierModel supplier) async {
    final collection = _suppliersCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }
    await collection.doc(supplier.id).update({
      ...supplier.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Supplier delete করো
  Future<void> deleteSupplier(String supplierId) async {
    final collection = _suppliersCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }
    await collection.doc(supplierId).delete();
  }

  /// Single supplier fetch করো (one-time read)
  Future<SupplierModel?> getSupplier(String supplierId) async {
    final collection = _suppliersCollection;
    if (collection == null) return null;

    final doc = await collection.doc(supplierId).get();
    if (!doc.exists) return null;
    return SupplierModel.fromFirestore(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  /// Name/company/phone অনুসারে client-side search
  List<SupplierModel> filterByQuery(
    List<SupplierModel> suppliers,
    String query,
  ) {
    if (query.trim().isEmpty) return suppliers;
    final lower = query.toLowerCase();
    return suppliers.where((s) {
      return s.name.toLowerCase().contains(lower) ||
          s.companyName.toLowerCase().contains(lower) ||
          s.phone.toLowerCase().contains(lower) ||
          (s.email != null && s.email!.toLowerCase().contains(lower));
    }).toList();
  }
}
