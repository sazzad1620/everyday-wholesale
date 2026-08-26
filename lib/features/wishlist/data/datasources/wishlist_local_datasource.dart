import 'package:injectable/injectable.dart';

import '../../../product/domain/entities/product_entity.dart';

/// In-memory, app-session-scoped storage — same approach as
/// `CartLocalDatasource`. Swapping in SharedPreferences (or, later, per-user
/// Firestore) only touches this file.
abstract class WishlistLocalDatasource {
  Future<List<ProductEntity>> addItem(ProductEntity product);

  Future<List<ProductEntity>> removeItem(String productId);
}

@LazySingleton(as: WishlistLocalDatasource)
class WishlistLocalDatasourceImpl implements WishlistLocalDatasource {
  final List<ProductEntity> _items = [];

  @override
  Future<List<ProductEntity>> addItem(ProductEntity product) async {
    if (!_items.any((item) => item.id == product.id)) {
      _items.add(product);
    }
    return List.unmodifiable(_items);
  }

  @override
  Future<List<ProductEntity>> removeItem(String productId) async {
    _items.removeWhere((item) => item.id == productId);
    return List.unmodifiable(_items);
  }
}
