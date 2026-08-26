import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_local_datasource.dart';

@LazySingleton(as: WishlistRepository)
class WishlistRepositoryImpl implements WishlistRepository {
  WishlistRepositoryImpl(this._datasource);

  final WishlistLocalDatasource _datasource;

  @override
  Future<Either<Failure, List<ProductEntity>>> addItem(ProductEntity product) async {
    try {
      return Right(await _datasource.addItem(product));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> removeItem(String productId) async {
    try {
      return Right(await _datasource.removeItem(productId));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
