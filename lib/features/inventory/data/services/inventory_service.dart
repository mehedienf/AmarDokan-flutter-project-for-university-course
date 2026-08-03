import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:amar_dokan/features/inventory/data/models/product_model.dart';

/// Inventory Service - Firestore এর সাথে communicate করে
///
/// এই class শুধু Firestore operations handle করে:
/// - Create (Add new product)
/// - Read (Get products)
/// - Update (Edit product)
/// - Delete (Remove product)
///
/// এটা কোনো UI state manage করে না — সেটা Provider এর কাজ
class InventoryService {
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current user এর ID return করে
  /// যদি user login না থাকে তাহলে exception throw করে
  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  /// Firestore collection reference
  /// Path: users/{userId}/products
  CollectionReference get _productsRef => _firestore
      .collection('users')
      .doc(_userId)
      .collection('products');

  // ============================================
  // CREATE - নতুন product add করা
  // ============================================

  /// Firestore এ নতুন product save করে
  /// Returns: save হওয়া product এর ID
  Future<String> addProduct(ProductModel product) async {
    try {
      // Firestore automatically ID generate করবে
      final docRef = await _productsRef.add(product.toFirestore());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception('Failed to add product: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ============================================
  // READ - Products পড়া
  // ============================================

  /// একবারে সব products fetch করে
  /// Returns: `List<ProductModel>`
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final querySnapshot = await _productsRef
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return ProductModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } on FirebaseException catch (e) {
      throw Exception('Failed to load products: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// একটা specific product এর ID দিয়ে fetch করে
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final docSnapshot = await _productsRef.doc(productId).get();

      if (!docSnapshot.exists) return null;

      return ProductModel.fromFirestore(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    } on FirebaseException catch (e) {
      throw Exception('Failed to load product: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Real-time stream - database এ কোনো পরিবর্তন হলে automatic update আসবে
  /// এটা `Stream<List<ProductModel>>` return করে যেটা Provider এ listen করবে
  Stream<List<ProductModel>> getProductsStream() {
    return _productsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Category অনুসারে filter করে products fetch করে
  Stream<List<ProductModel>> getProductsByCategory(String category) {
    return _productsRef
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Low stock products এর stream
  Stream<List<ProductModel>> getLowStockProducts() {
    return _productsRef
        .orderBy('stock')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .where((product) => product.isLowStock)
          .toList();
    });
  }

  // ============================================
  // UPDATE - Product update করা
  // ============================================

  /// Existing product এর data update করে
  Future<void> updateProduct(ProductModel product) async {
    try {
      // updatedAt automatically নতুন time set করি
      final updatedProduct = product.copyWith(
        updatedAt: DateTime.now(),
      );

      await _productsRef
          .doc(product.id)
          .update(updatedProduct.toFirestore());
    } on FirebaseException catch (e) {
      throw Exception('Failed to update product: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// শুধু stock update করার জন্য (sale এর পর)
  Future<void> updateStock(String productId, int newStock) async {
    try {
      await _productsRef.doc(productId).update({
        'stock': newStock,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw Exception('Failed to update stock: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ============================================
  // DELETE - Product মুছে ফেলা
  // ============================================

  /// Product কে Firestore থেকে delete করে
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsRef.doc(productId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete product: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ============================================
  // SEARCH - Product খোঁজা
  // ============================================

  /// Product name দিয়ে search করে
  /// Note: Firestore এ full-text search built-in নেই,
  /// তাই আমরা simple approach ব্যবহার করছি
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      // সব products নিয়ে locally filter করি
      // ছোট dataset এ এটা ভালো কাজ করে
      final allProducts = await getAllProducts();

      final lowercaseQuery = query.toLowerCase();
      return allProducts.where((product) {
        return product.name.toLowerCase().contains(lowercaseQuery) ||
            product.sku.toLowerCase().contains(lowercaseQuery) ||
            (product.description?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  // ============================================
  // STATISTICS - Reports এর জন্য
  // ============================================

  /// Total products count
  Future<int> getProductCount() async {
    try {
      final snapshot = await _productsRef.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Total stock value (সব products এর purchase price * stock)
  Future<double> getTotalStockValue() async {
    try {
      final products = await getAllProducts();
      return products.fold<double>(
        0,
        (total, product) => total + product.totalStockValue,
      );
    } catch (e) {
      return 0;
    }
  }
}