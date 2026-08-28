import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../entities/cart_item_entity.dart';

/// Every method returns the full, updated cart — keeps the bloc a thin
/// pass-through (just emit whatever comes back) with a single source of
/// truth for the current contents.
abstract class CartRepository {
  /// Current signed-in user's cart. Used on app start / sign-in to populate
  /// `CartBloc`'s initial state — the mutating methods below also return the
  /// resulting list, but nothing calls this on its own otherwise.
  Future<Either<Failure, List<CartItemEntity>>> getCart();

  Future<Either<Failure, List<CartItemEntity>>> addItem(ProductEntity product, int quantity);

  Future<Either<Failure, List<CartItemEntity>>> updateQuantity(String productId, int quantity);

  Future<Either<Failure, List<CartItemEntity>>> removeItem(String productId);

  Future<Either<Failure, List<CartItemEntity>>> clear();
}
