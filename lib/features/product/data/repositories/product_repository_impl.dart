import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_mock_datasource.dart';

@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._datasource);

  final ProductMockDatasource _datasource;

  @override
  Future<Either<Failure, List<ProductEntity>>> getProductsByCategory(
    String categoryId, {
    String? subcategoryId,
  }) async {
    try {
      return Right(await _datasource.getProductsByCategory(categoryId, subcategoryId: subcategoryId));
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
}
