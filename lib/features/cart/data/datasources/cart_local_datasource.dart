import 'package:injectable/injectable.dart';

import '../../../product/domain/entities/product_entity.dart';
import '../../domain/entities/cart_item_entity.dart';

/// In-memory, app-session-scoped storage. Swapping in SharedPreferences (or,
/// later, per-user Firestore) only touches this file.
abstract class CartLocalDatasource {
  Future<List<CartItemEntity>> addItem(ProductEntity product, int quantity);

  Future<List<CartItemEntity>> updateQuantity(String productId, int quantity);

  Future<List<CartItemEntity>> removeItem(String productId);

  Future<List<CartItemEntity>> clear();
}

@LazySingleton(as: CartLocalDatasource)
class CartLocalDatasourceImpl implements CartLocalDatasource {
  final List<CartItemEntity> _items = [];

  @override
  Future<List<CartItemEntity>> addItem(ProductEntity product, int quantity) async {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      _items.add(CartItemEntity(product: product, quantity: quantity));
    } else {
      _items[index] = CartItemEntity(product: product, quantity: _items[index].quantity + quantity);
    }
    return List.unmodifiable(_items);
  }

  @override
  Future<List<CartItemEntity>> updateQuantity(String productId, int quantity) async {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = CartItemEntity(product: _items[index].product, quantity: quantity);
      }
    }
    return List.unmodifiable(_items);
  }

  @override
  Future<List<CartItemEntity>> removeItem(String productId) async {
    _items.removeWhere((item) => item.product.id == productId);
    return List.unmodifiable(_items);
  }

  @override
  Future<List<CartItemEntity>> clear() async {
    _items.clear();
    return List.unmodifiable(_items);
  }
}
