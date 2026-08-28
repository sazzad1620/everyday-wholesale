import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../product/domain/entities/product_entity.dart';

/// Write-side (+ unscoped list-read) counterpart to [ProductRepository],
/// which only ever reads scoped by category — the admin list needs every
/// product regardless of category, and only the admin side ever mutates one.
abstract class AdminProductRepository {
  Future<Either<Failure, List<ProductEntity>>> getAllProducts();

  Future<Either<Failure, void>> createProduct(ProductEntity product);

  Future<Either<Failure, void>> updateProduct(ProductEntity product);

  Future<Either<Failure, void>> deleteProduct(String productId);
}
