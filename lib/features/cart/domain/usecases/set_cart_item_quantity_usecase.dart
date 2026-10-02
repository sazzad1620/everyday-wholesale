import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

class SetCartItemQuantityParams extends Equatable {
  const SetCartItemQuantityParams({required this.productId, required this.quantity});

  final String productId;

  /// Zero or below removes the item.
  final int quantity;

  @override
  List<Object?> get props => [productId, quantity];
}

@injectable
class SetCartItemQuantityUseCase extends UseCase<void, SetCartItemQuantityParams> {
  SetCartItemQuantityUseCase(this._repository);

  final CartRepository _repository;

  @override
  Future<Either<Failure, void>> call(SetCartItemQuantityParams params) =>
      _repository.setQuantity(params.productId, params.quantity);
}
