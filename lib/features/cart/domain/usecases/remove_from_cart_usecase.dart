import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/cart_item_entity.dart';
import '../repositories/cart_repository.dart';

@injectable
class RemoveFromCartUseCase extends UseCase<List<CartItemEntity>, String> {
  RemoveFromCartUseCase(this._repository);

  final CartRepository _repository;

  @override
  Future<Either<Failure, List<CartItemEntity>>> call(String productId) => _repository.removeItem(productId);
}
