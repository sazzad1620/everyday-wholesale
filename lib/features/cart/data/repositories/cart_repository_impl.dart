import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_datasource.dart';

@LazySingleton(as: CartRepository)
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._datasource);

  final CartRemoteDatasource _datasource;

  @override
  Future<Either<Failure, List<CartItemEntity>>> getCart() => _guard(_datasource.getCart);

  @override
  Future<Either<Failure, void>> setQuantity(String productId, int quantity) =>
      _guard(() => _datasource.setQuantity(productId, quantity));

  @override
  Future<Either<Failure, void>> incrementQuantity(String productId, int by) =>
      _guard(() => _datasource.incrementQuantity(productId, by));

  @override
  Future<Either<Failure, void>> clear() => _guard(_datasource.clear);

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.messageKey));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
