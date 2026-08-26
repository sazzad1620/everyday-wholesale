import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../product/domain/entities/product_entity.dart';

/// Every method returns the full, updated wishlist — keeps the bloc a thin
/// pass-through (just emit whatever comes back) with a single source of
/// truth for the current contents. Same shape as `CartRepository`.
abstract class WishlistRepository {
  Future<Either<Failure, List<ProductEntity>>> addItem(ProductEntity product);

  Future<Either<Failure, List<ProductEntity>>> removeItem(String productId);
}
