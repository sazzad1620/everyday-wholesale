import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/cart_totals.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../entities/order_entity.dart';

abstract class OrderRepository {
  Future<Either<Failure, OrderEntity>> placeOrder({
    required List<CartItemEntity> cartItems,
    required CartTotals totals,
    required String paymentMethod,
    required String addressLine,
    required String addressPhone,
  });

  /// Newest first. Only ever returns the signed-in user's own orders — the
  /// query is already scoped to `customerId == current uid`.
  Future<Either<Failure, List<OrderEntity>>> getOrderHistory();
}
