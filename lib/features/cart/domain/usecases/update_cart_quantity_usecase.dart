import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/cart_item_entity.dart';
import '../repositories/cart_repository.dart';

class UpdateCartQuantityParams extends Equatable {
  const UpdateCartQuantityParams({required this.productId, required this.quantity});

  final String productId;

  /// Zero or below removes the item.
  final int quantity;

  @override
  List<Object?> get props => [productId, quantity];
}

@injectable
class UpdateCartQuantityUseCase extends UseCase<List<CartItemEntity>, UpdateCartQuantityParams> {
  UpdateCartQuantityUseCase(this._repository);

  final CartRepository _repository;

  @override
  Future<Either<Failure, List<CartItemEntity>>> call(UpdateCartQuantityParams params) {
    return _repository.updateQuantity(params.productId, params.quantity);
  }
}
