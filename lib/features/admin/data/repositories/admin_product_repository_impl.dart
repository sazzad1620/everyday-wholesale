import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../product/data/models/product_model.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../domain/repositories/admin_product_repository.dart';
import '../datasources/admin_product_remote_datasource.dart';

@LazySingleton(as: AdminProductRepository)
class AdminProductRepositoryImpl implements AdminProductRepository {
  AdminProductRepositoryImpl(this._datasource);

  final AdminProductRemoteDatasource _datasource;

  @override
  Future<Either<Failure, List<ProductEntity>>> getAllProducts() async {
    try {
      return Right(await _datasource.getAllProducts());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> createProduct(ProductEntity product) async {
    try {
      await _datasource.createProduct(_toModel(product));
      return const Right(null);
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(ProductEntity product) async {
    try {
      await _datasource.updateProduct(_toModel(product));
      return const Right(null);
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String productId) async {
    try {
      await _datasource.deleteProduct(productId);
      return const Right(null);
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  ProductModel _toModel(ProductEntity product) => ProductModel(
    id: product.id,
    name: product.name,
    price: product.price,
    unit: product.unit,
    categoryId: product.categoryId,
    iconKey: product.iconKey,
    description: product.description,
    condition: product.condition,
    origin: product.origin,
    subcategoryId: product.subcategoryId,
    imageUrl: product.imageUrl,
    inStock: product.inStock,
    reviews: product.reviews,
  );
}
