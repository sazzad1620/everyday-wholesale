import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../entities/cart_item_entity.dart';
import '../repositories/cart_repository.dart';

class AddToCartParams extends Equatable {
  const AddToCartParams({required this.product, required this.quantity});

  final ProductEntity product;
  final int quantity;

  @override
  List<Object?> get props => [product, quantity];
}

@injectable
class AddToCartUseCase extends UseCase<List<CartItemEntity>, AddToCartParams> {
  AddToCartUseCase(this._repository);

  final CartRepository _repository;

  @override
  Future<Either<Failure, List<CartItemEntity>>> call(AddToCartParams params) {
    return _repository.addItem(params.product, params.quantity);
  }
}
