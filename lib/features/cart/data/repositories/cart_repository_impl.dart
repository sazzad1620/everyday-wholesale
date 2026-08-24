import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_datasource.dart';

@LazySingleton(as: CartRepository)
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._datasource);

  final CartLocalDatasource _datasource;

  @override
  Future<Either<Failure, List<CartItemEntity>>> addItem(ProductEntity product, int quantity) async {
    try {
      return Right(await _datasource.addItem(product, quantity));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<CartItemEntity>>> updateQuantity(String productId, int quantity) async {
    try {
      return Right(await _datasource.updateQuantity(productId, quantity));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<CartItemEntity>>> removeItem(String productId) async {
    try {
      return Right(await _datasource.removeItem(productId));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<CartItemEntity>>> clear() async {
    try {
      return Right(await _datasource.clear());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
