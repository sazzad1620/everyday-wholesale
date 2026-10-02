import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../product/data/datasources/product_remote_datasource.dart';
import '../../domain/entities/cart_item_entity.dart';

/// Per-user cart at `users/{uid}/cart/{productId}` — doc only stores
/// `quantity`; the actual product data is resolved fresh via
/// [ProductRemoteDatasource] when the cart is loaded, so cart contents never
/// drift from the real product (price changes, goes out of stock, etc.).
///
/// Writes deliberately return nothing: `CartBloc` updates the screen
/// optimistically and only needs to know whether a write succeeded — it no
/// longer re-reads the whole cart (and every product in it) after each tap.
abstract class CartRemoteDatasource {
  Future<List<CartItemEntity>> getCart();

  /// Sets an item's quantity; `<= 0` removes it.
  Future<void> setQuantity(String productId, int quantity);

  /// Adds [by] to whatever is stored, atomically — used for "Add to cart" on
  /// an item not yet in the local cart, so it merges with the saved cart
  /// even if that hasn't finished loading.
  Future<void> incrementQuantity(String productId, int by);

  Future<void> clear();
}

@LazySingleton(as: CartRemoteDatasource)
class CartRemoteDatasourceImpl implements CartRemoteDatasource {
  CartRemoteDatasourceImpl(this._firestore, this._firebaseAuth, this._productDatasource);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final ProductRemoteDatasource _productDatasource;

  CollectionReference<Map<String, dynamic>> get _cartCollection {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw const AuthException('errors.sign_in_required_cart');
    return _firestore.collection('users').doc(uid).collection('cart');
  }

  @override
  Future<List<CartItemEntity>> getCart() async {
    final snapshot = await _cartCollection.get();
    final entries = [
      for (final doc in snapshot.docs)
        if (((doc.data()['quantity'] as num?)?.toInt() ?? 0) > 0) (doc.id, (doc.data()['quantity'] as num).toInt()),
    ];
    // All products in parallel (was one-by-one — a 10-item cart took 10
    // sequential round trips to open).
    final products = await Future.wait(entries.map((e) => _productDatasource.getProductById(e.$1)));
    return [
      for (var i = 0; i < entries.length; i++)
        // Product may have been deleted by an admin since it was added —
        // silently drop it rather than showing a broken cart row.
        if (products[i] != null) CartItemEntity(product: products[i]!, quantity: entries[i].$2),
    ];
  }

  @override
  Future<void> setQuantity(String productId, int quantity) {
    final doc = _cartCollection.doc(productId);
    return quantity <= 0 ? doc.delete() : doc.set({'quantity': quantity});
  }

  @override
  Future<void> incrementQuantity(String productId, int by) =>
      _cartCollection.doc(productId).set({'quantity': FieldValue.increment(by)}, SetOptions(merge: true));

  @override
  Future<void> clear() async {
    final snapshot = await _cartCollection.get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
