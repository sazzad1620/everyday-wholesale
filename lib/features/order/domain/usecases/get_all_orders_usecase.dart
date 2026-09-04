import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order_entity.dart';
import '../repositories/admin_order_repository.dart';

@injectable
class GetAllOrdersUseCase extends UseCase<List<OrderEntity>, NoParams> {
  GetAllOrdersUseCase(this._repository);

  final AdminOrderRepository _repository;

  @override
  Future<Either<Failure, List<OrderEntity>>> call(NoParams params) => _repository.getAllOrders();
}
