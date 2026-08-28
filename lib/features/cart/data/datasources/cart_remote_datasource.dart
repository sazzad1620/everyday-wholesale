import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../product/data/datasources/product_remote_datasource.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../domain/entities/cart_item_entity.dart';

/// Per-user cart at `users/{uid}/cart/{productId}` — doc only stores
/// `quantity`; the actual product data is resolved fresh via
/// [ProductRemoteDatasource] on every read, so cart contents never drift
/// from the real product (price changes, goes out of stock, etc.).
abstract class CartRemoteDatasource {
  Future<List<CartItemEntity>> getCart();

  Future<List<CartItemEntity>> addItem(ProductEntity product, int quantity);

  Future<List<CartItemEntity>> updateQuantity(String productId, int quantity);

  Future<List<CartItemEntity>> removeItem(String productId);

  Future<List<CartItemEntity>> clear();
}

@LazySingleton(as: CartRemoteDatasource)
class CartRemoteDatasourceImpl implements CartRemoteDatasource {
  CartRemoteDatasourceImpl(this._firestore, this._firebaseAuth, this._productDatasource);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final ProductRemoteDatasource _productDatasource;

  CollectionReference<Map<String, dynamic>> get _cartCollection {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw const AuthException('Please sign in to use your cart.');
    return _firestore.collection('users').doc(uid).collection('cart');
  }

  Future<List<CartItemEntity>> _fetchItems() async {
    final snapshot = await _cartCollection.get();
    final items = <CartItemEntity>[];
    for (final doc in snapshot.docs) {
      final quantity = (doc.data()['quantity'] as num?)?.toInt() ?? 0;
      if (quantity <= 0) continue;
      final product = await _productDatasource.getProductById(doc.id);
      // Product may have been deleted by an admin since it was added —
      // silently drop it rather than showing a broken cart row.
      if (product != null) {
        items.add(CartItemEntity(product: product, quantity: quantity));
      }
    }
    return items;
  }

  @override
  Future<List<CartItemEntity>> getCart() => _fetchItems();

  @override
  Future<List<CartItemEntity>> addItem(ProductEntity product, int quantity) async {
    final docRef = _cartCollection.doc(product.id);
    final snapshot = await docRef.get();
    final currentQuantity = snapshot.exists ? ((snapshot.data()?['quantity'] as num?)?.toInt() ?? 0) : 0;
    await docRef.set({'quantity': currentQuantity + quantity});
    return _fetchItems();
  }

  @override
  Future<List<CartItemEntity>> updateQuantity(String productId, int quantity) async {
    final docRef = _cartCollection.doc(productId);
    if (quantity <= 0) {
      await docRef.delete();
    } else {
      await docRef.set({'quantity': quantity});
    }
    return _fetchItems();
  }

  @override
  Future<List<CartItemEntity>> removeItem(String productId) async {
    await _cartCollection.doc(productId).delete();
    return _fetchItems();
  }

  @override
  Future<List<CartItemEntity>> clear() async {
    final snapshot = await _cartCollection.get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return const [];
  }
}
