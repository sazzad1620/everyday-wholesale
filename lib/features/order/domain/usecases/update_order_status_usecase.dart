import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order_status.dart';
import '../repositories/admin_order_repository.dart';

@injectable
class UpdateOrderStatusUseCase extends UseCase<void, UpdateOrderStatusParams> {
  UpdateOrderStatusUseCase(this._repository);

  final AdminOrderRepository _repository;

  @override
  Future<Either<Failure, void>> call(UpdateOrderStatusParams params) =>
      _repository.updateOrderStatus(params.orderId, params.status);
}

class UpdateOrderStatusParams extends Equatable {
  const UpdateOrderStatusParams({required this.orderId, required this.status});

  final String orderId;
  final OrderStatus status;

  @override
  List<Object?> get props => [orderId, status];
}
