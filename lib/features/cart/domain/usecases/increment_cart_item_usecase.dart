import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

class IncrementCartItemParams extends Equatable {
  const IncrementCartItemParams({required this.productId, required this.by});

  final String productId;
  final int by;

  @override
  List<Object?> get props => [productId, by];
}

/// Atomic add — merges with whatever the saved cart already holds.
@injectable
class IncrementCartItemUseCase extends UseCase<void, IncrementCartItemParams> {
  IncrementCartItemUseCase(this._repository);

  final CartRepository _repository;

  @override
  Future<Either<Failure, void>> call(IncrementCartItemParams params) =>
      _repository.incrementQuantity(params.productId, params.by);
}
