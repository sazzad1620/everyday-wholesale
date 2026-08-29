import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../models/product_model.dart';

abstract class ProductRemoteDatasource {
  Future<List<ProductModel>> getProductsByCategory(String categoryId, {String? subcategoryId});

  Future<ProductModel?> getProductById(String id);

  Future<List<ProductModel>> searchProducts(String query);
}

@LazySingleton(as: ProductRemoteDatasource)
class ProductRemoteDatasourceImpl implements ProductRemoteDatasource {
  ProductRemoteDatasourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const _productsCollection = 'products';

  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId, {String? subcategoryId}) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_productsCollection)
        .where('categoryId', isEqualTo: categoryId);
    if (subcategoryId != null) {
      query = query.where('subcategoryId', isEqualTo: subcategoryId);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), id: doc.id)).toList();
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    final doc = await _firestore.collection(_productsCollection).doc(id).get();
    if (!doc.exists) return null;
    return ProductModel.fromMap(doc.data()!, id: doc.id);
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    // Firestore has no case-insensitive substring query, and the catalog is
    // small enough (tens of products) that fetching everything and filtering
    // client-side is simpler and cheap enough — no search index service
    // needed at this scale.
    final snapshot = await _firestore.collection(_productsCollection).get();
    final lowerQuery = query.toLowerCase();
    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data(), id: doc.id))
        .where((product) => product.name.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
