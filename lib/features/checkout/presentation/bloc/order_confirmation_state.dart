import 'package:equatable/equatable.dart';

import '../../../order/domain/entities/order_entity.dart';

class OrderConfirmationState extends Equatable {
  const OrderConfirmationState({this.order});

  /// Latest snapshot from `watchOrder` — starts as whatever `PlaceOrderUseCase`
  /// returned (passed in as the page's initial `order`) and updates live as
  /// the webhook (or the reconciliation safety net) flips `paymentStatus`.
  final OrderEntity? order;

  @override
  List<Object?> get props => [order];
}
