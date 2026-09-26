import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  /// [categoryId] may be `mostPopularCategoryId`, which lists every product
  /// flagged Most Popular instead of matching a real category.
  Future<Either<Failure, List<ProductEntity>>> getProductsByCategory(String categoryId, {String? subcategoryId});

  Future<Either<Failure, List<ProductEntity>>> getMostPopularProducts();

  Future<Either<Failure, ProductEntity>> getProductById(String id);

  /// Case-insensitive substring match against every product's name.
  Future<Either<Failure, List<ProductEntity>>> searchProducts(String query);
}
