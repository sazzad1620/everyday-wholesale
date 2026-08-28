import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../product/data/models/product_model.dart';

abstract class AdminProductRemoteDatasource {
  Future<List<ProductModel>> getAllProducts();

  Future<void> createProduct(ProductModel product);

  Future<void> updateProduct(ProductModel product);

  Future<void> deleteProduct(String productId);
}

@LazySingleton(as: AdminProductRemoteDatasource)
class AdminProductRemoteDatasourceImpl implements AdminProductRemoteDatasource {
  AdminProductRemoteDatasourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const _productsCollection = 'products';

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final snapshot = await _firestore.collection(_productsCollection).get();
    return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), id: doc.id)).toList();
  }

  @override
  // `product.id` is a caller-side placeholder here (unlike categories,
  // products have no natural stable slug) — a fresh Firestore-generated doc
  // id is used instead, same as any other auto-id collection.
  Future<void> createProduct(ProductModel product) =>
      _firestore.collection(_productsCollection).doc().set(product.toMap());

  @override
  Future<void> updateProduct(ProductModel product) =>
      _firestore.collection(_productsCollection).doc(product.id).set(product.toMap());

  @override
  Future<void> deleteProduct(String productId) =>
      _firestore.collection(_productsCollection).doc(productId).delete();
}
