import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/text_normalizer.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDatasource {
  Future<List<ProductModel>> getProductsByCategory(String categoryId, {String? subcategoryId, int? limit});

  Future<List<ProductModel>> getMostPopularProducts();

  Future<ProductModel?> getProductById(String id);

  Future<List<ProductModel>> searchProducts(String query);
}

@LazySingleton(as: ProductRemoteDatasource)
class ProductRemoteDatasourceImpl implements ProductRemoteDatasource {
  ProductRemoteDatasourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const _productsCollection = 'products';

  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId, {String? subcategoryId, int? limit}) async {
    // Home-page rows ask for the first few products of *every* category. On
    // web each Firestore query costs a round trip over the database channel
    // (~0.2–0.3 s from Bangladesh), and a dozen of them made the rows arrive in
    // waves for several seconds. They all read from the one shared catalogue
    // load instead (same document order as the per-category query).
    if (limit != null && subcategoryId == null) {
      final catalog = await _catalog();
      return catalog.where((p) => p.categoryId == categoryId).take(limit).toList();
    }
    Query<Map<String, dynamic>> query = _firestore
        .collection(_productsCollection)
        .where('categoryId', isEqualTo: categoryId);
    if (subcategoryId != null) {
      query = query.where('subcategoryId', isEqualTo: subcategoryId);
    }
    if (limit != null) query = query.limit(limit);
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), id: doc.id)).toList();
  }

  @override
  Future<List<ProductModel>> getMostPopularProducts() async {
    final snapshot = await _firestore.collection(_productsCollection).where('isMostPopular', isEqualTo: true).get();
    return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), id: doc.id)).toList();
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    final doc = await _firestore.collection(_productsCollection).doc(id).get();
    if (!doc.exists) return null;
    return ProductModel.fromMap(doc.data()!, id: doc.id);
  }

  /// The whole catalogue, shared by every search. Searching used to re-read
  /// every product document on each (debounced) keystroke; now the first
  /// search loads it and later ones filter the same list. Kept for
  /// [_catalogTtl], so an edit made by an admin shows up within that window.
  Future<List<ProductModel>>? _catalogRequest;
  DateTime? _catalogLoadedAt;
  static const _catalogTtl = Duration(minutes: 2);

  Future<List<ProductModel>> _catalog() {
    final loadedAt = _catalogLoadedAt;
    final request = _catalogRequest;
    if (request != null && loadedAt != null && DateTime.now().difference(loadedAt) < _catalogTtl) {
      return request;
    }
    _catalogLoadedAt = DateTime.now();
    return _catalogRequest = _loadCatalog();
  }

  Future<List<ProductModel>> _loadCatalog() async {
    try {
      final snapshot = await _firestore.collection(_productsCollection).get();
      return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), id: doc.id)).toList();
    } catch (_) {
      // Don't cache a failure — the next keystroke should try again.
      _catalogRequest = null;
      _catalogLoadedAt = null;
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    // Firestore has no case-insensitive text search, and the catalogue is
    // small enough (tens to a few hundred products) that filtering
    // client-side is simpler and cheap — no search index service needed.
    // Matching is word-wise (every word typed must begin a word of the name,
    // in either language; see `searchRank`) and the best matches come first.
    final products = await _catalog();
    return filterBySearch<ProductModel>(products, query, (product) => product.name.values);
  }
}
