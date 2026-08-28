import 'package:equatable/equatable.dart';

import '../../../order/domain/entities/order_entity.dart';

class CheckoutState extends Equatable {
  const CheckoutState({this.isPlacingOrder = false, this.errorMessage, this.placedOrder});

  final bool isPlacingOrder;
  final String? errorMessage;

  /// Set once "Place Order" succeeds — the confirmation page reads its `id`.
  final OrderEntity? placedOrder;

  @override
  List<Object?> get props => [isPlacingOrder, errorMessage, placedOrder];
}
