import 'dart:async';

import 'package:amar_dokan/core/local/local_db.dart';

import 'package:amar_dokan/features/customers/data/models/customer_model.dart';

/// CustomerService - storage এর সাথে customer data manage করে
///
/// storage path: users/{userId}/customers/{customerId}
///
/// এই service এর কাজ:
/// - Real-time stream দিয়ে customer list পাওয়া
/// - Customer add/update/delete করা
/// - Search query দিয়ে filter করা
class CustomerService {
  final LocalDb _firestore;
  final LocalAuth _auth;

  CustomerService({
    LocalDb? firestore,
    LocalAuth? auth,
  })  : _firestore = firestore ?? LocalDb.instance,
        _auth = auth ?? LocalAuth.instance;

  /// Current user এর customers collection reference
  CollectionReference? get _customersCollection {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('customers');
  }

  /// Real-time stream of all customers (newest first)
  /// Authenticated user না থাকলে empty stream দেয়
  Stream<List<CustomerModel>> getCustomersStream() {
    final collection = _customersCollection;
    if (collection == null) return Stream.value([]);

    return collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                CustomerModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// নতুন customer add করো
  Future<String> addCustomer(CustomerModel customer) async {
    final collection = _customersCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }
    final docRef = await collection.add(customer.toFirestore());
    return docRef.id;
  }

  /// Existing customer update করো
  Future<void> updateCustomer(CustomerModel customer) async {
    final collection = _customersCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }
    await collection.doc(customer.id).update({
      ...customer.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Customer delete করো
  Future<void> deleteCustomer(String customerId) async {
    final collection = _customersCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }
    await collection.doc(customerId).delete();
  }

  /// Single customer fetch করো (one-time read)
  Future<CustomerModel?> getCustomer(String customerId) async {
    final collection = _customersCollection;
    if (collection == null) return null;

    final doc = await collection.doc(customerId).get();
    if (!doc.exists) return null;
    return CustomerModel.fromFirestore(
      doc.data(),
      doc.id,
    );
  }

  /// Name/phone অনুসারে client-side search (stream filtered)
  /// যদি backend search দরকার হয়, এটা swap করা যাবে
  List<CustomerModel> filterByQuery(
    List<CustomerModel> customers,
    String query,
  ) {
    if (query.trim().isEmpty) return customers;
    final lower = query.toLowerCase();
    return customers.where((c) {
      return c.name.toLowerCase().contains(lower) ||
          c.phone.toLowerCase().contains(lower) ||
          (c.email != null && c.email!.toLowerCase().contains(lower));
    }).toList();
  }
}
