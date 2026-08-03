import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:amar_dokan/features/accounting/data/models/transaction_model.dart';

/// TransactionService - Firestore এর সাথে transactions data manage করে।
///
/// Firestore path: users/{userId}/transactions/{transactionId}
class TransactionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TransactionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference? get _transactionsCollection {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions');
  }

  // ============================================
  // Streams
  // ============================================

  Stream<List<TransactionModel>> getTransactionsStream() {
    final collection = _transactionsCollection;
    if (collection == null) return Stream.value([]);

    return collection
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<TransactionModel>> getTransactionsByTypeStream(
    TransactionType type,
  ) {
    final collection = _transactionsCollection;
    if (collection == null) return Stream.value([]);

    return collection
        .where('type', isEqualTo: type.toJson())
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<TransactionModel>> getTransactionsByDateRangeStream(
    DateTime startDate,
    DateTime endDate,
  ) {
    final collection = _transactionsCollection;
    if (collection == null) return Stream.value([]);

    return collection
        .where('transactionDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('transactionDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // ============================================
  // CRUD
  // ============================================

  /// Add a new transaction.
  Future<String> addTransaction(TransactionModel txn) async {
    final collection = _transactionsCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    final docRef = await collection.add(txn.toFirestore());
    return docRef.id;
  }

  /// Update an existing transaction.
  Future<void> updateTransaction(TransactionModel txn) async {
    final collection = _transactionsCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }
    await collection.doc(txn.id).update({
      ...txn.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a transaction.
  Future<void> deleteTransaction(String transactionId) async {
    final collection = _transactionsCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }
    await collection.doc(transactionId).delete();
  }

  Future<TransactionModel?> getTransaction(String transactionId) async {
    final collection = _transactionsCollection;
    if (collection == null) return null;

    final doc = await collection.doc(transactionId).get();
    if (!doc.exists) return null;
    return TransactionModel.fromFirestore(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  // ============================================
  // Aggregations
  // ============================================

  /// Total income within date range.
  Future<double> getTotalIncome(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final collection = _transactionsCollection;
    if (collection == null) return 0.0;

    final snapshot = await collection
        .where('type', isEqualTo: TransactionType.income.toJson())
        .where('transactionDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('transactionDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] ?? 0).toDouble();
    }
    return total;
  }

  /// Total expense within date range.
  Future<double> getTotalExpense(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final collection = _transactionsCollection;
    if (collection == null) return 0.0;

    final snapshot = await collection
        .where('type', isEqualTo: TransactionType.expense.toJson())
        .where('transactionDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('transactionDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] ?? 0).toDouble();
    }
    return total;
  }

  /// Net cash flow (income - expense) within date range.
  Future<double> getNetCashFlow(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final income = await getTotalIncome(startDate, endDate);
    final expense = await getTotalExpense(startDate, endDate);
    return income - expense;
  }

  /// Total amount for a specific category within date range.
  Future<double> getTotalByCategory(
    TransactionCategory category,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final collection = _transactionsCollection;
    if (collection == null) return 0.0;

    final snapshot = await collection
        .where('category', isEqualTo: category.toJson())
        .where('transactionDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('transactionDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] ?? 0).toDouble();
    }
    return total;
  }

  /// Generate next reference number (e.g. TXN-000001).
  Future<String> generateNextReferenceNumber() async {
    final collection = _transactionsCollection;
    if (collection == null) return 'TXN-000001';

    final snapshot = await collection.count().get();
    final count = snapshot.count ?? 0;
    final next = count + 1;
    return 'TXN-${next.toString().padLeft(6, '0')}';
  }

  // ============================================
  // Client-side filter helpers
  // ============================================

  List<TransactionModel> filterByQuery(
    List<TransactionModel> transactions,
    String query,
  ) {
    if (query.trim().isEmpty) return transactions;
    final lower = query.toLowerCase();
    return transactions.where((t) {
      return t.referenceNumber.toLowerCase().contains(lower) ||
          (t.partyName?.toLowerCase().contains(lower) ?? false) ||
          (t.description?.toLowerCase().contains(lower) ?? false) ||
          (t.notes?.toLowerCase().contains(lower) ?? false) ||
          t.category.label.toLowerCase().contains(lower);
    }).toList();
  }

  List<TransactionModel> filterByType(
    List<TransactionModel> transactions,
    TransactionType type,
  ) {
    return transactions.where((t) => t.type == type).toList();
  }

  List<TransactionModel> filterByCategory(
    List<TransactionModel> transactions,
    TransactionCategory category,
  ) {
    return transactions.where((t) => t.category == category).toList();
  }

  List<TransactionModel> filterByDateRange(
    List<TransactionModel> transactions,
    DateTime start,
    DateTime end,
  ) {
    return transactions.where((t) {
      final date = t.transactionDate;
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }
}
