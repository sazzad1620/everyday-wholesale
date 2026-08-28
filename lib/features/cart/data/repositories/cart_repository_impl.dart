import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_datasource.dart';

@LazySingleton(as: CartRepository)
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._datasource);

  final CartRemoteDatasource _datasource;

  @override
  Future<Either<Failure, List<CartItemEntity>>> getCart() async {
    try {
      return Right(await _datasource.getCart());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<CartItemEntity>>> addItem(ProductEntity product, int quantity) async {
    try {
      return Right(await _datasource.addItem(product, quantity));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<CartItemEntity>>> updateQuantity(String productId, int quantity) async {
    try {
      return Right(await _datasource.updateQuantity(productId, quantity));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<CartItemEntity>>> removeItem(String productId) async {
    try {
      return Right(await _datasource.removeItem(productId));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<CartItemEntity>>> clear() async {
    try {
      return Right(await _datasource.clear());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
