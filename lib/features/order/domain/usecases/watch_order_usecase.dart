import 'package:injectable/injectable.dart';

import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

@injectable
class WatchOrderUseCase {
  WatchOrderUseCase(this._repository);

  final OrderRepository _repository;

  Stream<OrderEntity> call(String orderId) => _repository.watchOrder(orderId);
}
