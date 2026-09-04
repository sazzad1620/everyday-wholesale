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
    required String addressReceiverName,
  });

  /// Newest first. Only ever returns the signed-in user's own orders — the
  /// query is already scoped to `customerId == current uid`.
  Future<Either<Failure, List<OrderEntity>>> getOrderHistory();

  /// Live updates for one order — used by the order-confirmation screen to
  /// reflect `paymentStatus` as it's actually resolved server-side (by
  /// `stripeWebhook`/`reconcilePendingPayments`), instead of a one-shot read
  /// that would just show whatever it was at page-load time.
  Stream<OrderEntity> watchOrder(String orderId);
}
