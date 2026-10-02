import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/cart_item_entity.dart';

/// Reads return the cart; writes only report success/failure — `CartBloc`
/// applies every change to the screen immediately (optimistic update) and
/// persists it in the background, reloading via [getCart] only if a write
/// fails.
abstract class CartRepository {
  /// Current signed-in user's cart (on app start / sign-in, or to recover
  /// from a failed write).
  Future<Either<Failure, List<CartItemEntity>>> getCart();

  /// Sets an item's quantity; `<= 0` removes it.
  Future<Either<Failure, void>> setQuantity(String productId, int quantity);

  /// Atomically adds [by] to the stored quantity (creating the item).
  Future<Either<Failure, void>> incrementQuantity(String productId, int by);

  Future<Either<Failure, void>> clear();
}
