import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/domain/entities/order_status.dart';

/// Write-side/unscoped counterpart to [OrderRepository]'s customer-scoped
/// `getOrderHistory` — only the admin side ever reads every order or changes
/// its status.
abstract class AdminOrderRepository {
  /// Newest first, every customer's orders.
  Future<Either<Failure, List<OrderEntity>>> getAllOrders();

  Future<Either<Failure, void>> updateOrderStatus(String orderId, OrderStatus status);
}
