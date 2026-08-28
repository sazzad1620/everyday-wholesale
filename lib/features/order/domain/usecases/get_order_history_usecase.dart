import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

@injectable
class GetOrderHistoryUseCase extends UseCase<List<OrderEntity>, NoParams> {
  GetOrderHistoryUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Either<Failure, List<OrderEntity>>> call(NoParams params) => _repository.getOrderHistory();
}
