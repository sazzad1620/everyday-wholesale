import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../home/domain/entities/most_popular_category.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._datasource);

  final ProductRemoteDatasource _datasource;

  @override
  Future<Either<Failure, List<ProductEntity>>> getProductsByCategory(
    String categoryId, {
    String? subcategoryId,
    int? limit,
  }) async {
    if (categoryId == mostPopularCategoryId) return getMostPopularProducts();
    try {
      return Right(await _datasource.getProductsByCategory(categoryId, subcategoryId: subcategoryId, limit: limit));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getMostPopularProducts() async {
    try {
      return Right(await _datasource.getMostPopularProducts());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getProductById(String id) async {
    try {
      final product = await _datasource.getProductById(id);
      if (product == null) return const Left(NotFoundFailure());
      return Right(product);
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> searchProducts(String query) async {
    try {
      return Right(await _datasource.searchProducts(query));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
