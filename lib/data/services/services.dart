import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

// ─── PRODUCT SERVICE ───────────────────────────────────────────
class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream all products
  Stream<List<ProductModel>> getProducts() {
    return _db
        .collection('products')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ProductModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Stream featured products
  Stream<List<ProductModel>> getFeaturedProducts() {
    return _db
        .collection('products')
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ProductModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Stream products by category
  Stream<List<ProductModel>> getProductsByCategory(String category) {
    if (category == 'All') return getProducts();
    return _db
        .collection('products')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ProductModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Get single product
  Future<ProductModel?> getProduct(String id) async {
    final doc = await _db.collection('products').doc(id).get();
    if (doc.exists) return ProductModel.fromMap(doc.data()!, doc.id);
    return null;
  }

  /// Search products by name
  Future<List<ProductModel>> searchProducts(String query) async {
    final snap = await _db.collection('products').get();
    return snap.docs
        .map((d) => ProductModel.fromMap(d.data(), d.id))
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}


// ─── CART SERVICE ──────────────────────────────────────────────
class CartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _cartRef(String userId) =>
      _db.collection('users').doc(userId).collection('cart');

  /// Stream cart items
  Stream<List<CartItemModel>> getCartItems(String userId) {
    return _cartRef(userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CartItemModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  /// Add item to cart
  Future<void> addToCart(String userId, CartItemModel item) async {
    // Check if already in cart
    final existing = await _cartRef(userId)
        .where('productId', isEqualTo: item.productId)
        .where('size', isEqualTo: item.size)
        .get();

    if (existing.docs.isNotEmpty) {
      // Increment quantity
      final doc = existing.docs.first;
      final current = (doc.data() as Map<String, dynamic>)['quantity'] ?? 1;
      await doc.reference.update({'quantity': current + 1});
    } else {
      await _cartRef(userId).add(item.toMap());
    }
  }

  /// Update quantity
  Future<void> updateQuantity(String userId, String itemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(userId, itemId);
    } else {
      await _cartRef(userId).doc(itemId).update({'quantity': quantity});
    }
  }

  /// Remove item
  Future<void> removeFromCart(String userId, String itemId) async {
    await _cartRef(userId).doc(itemId).delete();
  }

  /// Clear entire cart
  Future<void> clearCart(String userId) async {
    final snap = await _cartRef(userId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}


// ─── ORDER SERVICE ─────────────────────────────────────────────
class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Place a new order
  Future<String> placeOrder(OrderModel order) async {
    final ref = await _db.collection('orders').add(order.toMap());
    return ref.id;
  }

  /// Stream user's orders
  Stream<List<OrderModel>> getUserOrders(String userId) {
  return _db
      .collection('orders')
      .where('userId', isEqualTo: userId)
      .snapshots()                          // ← removed orderBy to avoid index error
      .map((snap) => snap.docs
          .map((d) => OrderModel.fromMap(d.data(), d.id))
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt))); // ← sort in Dart
}

  /// Get single order
  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _db.collection('orders').doc(orderId).get();
    if (doc.exists) return OrderModel.fromMap(doc.data()!, doc.id);
    return null;
  }
}
