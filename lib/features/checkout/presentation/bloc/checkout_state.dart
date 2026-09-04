import 'package:equatable/equatable.dart';

import '../../../order/domain/entities/order_entity.dart';

class CheckoutState extends Equatable {
  const CheckoutState({
    this.isPlacingOrder = false,
    this.errorMessage,
    this.placedOrder,
    this.pendingPaymentClientSecret,
    this.paymentConfirmed = false,
  });

  final bool isPlacingOrder;
  final String? errorMessage;

  /// Set once the order doc is written — for Cash this happens together
  /// with [paymentConfirmed]; for Card it's set first, while payment is
  /// still pending.
  final OrderEntity? placedOrder;

  /// Set once a PaymentIntent exists for [placedOrder] — the page reacts by
  /// presenting the platform payment UI (`PaymentSheet`/`CardField`), then
  /// reports the outcome back via [CheckoutPaymentConfirmed]/
  /// [CheckoutPaymentFailed]. Always null for Cash on Delivery, which never
  /// goes through Stripe.
  final String? pendingPaymentClientSecret;

  /// True once the order is genuinely done — Cash immediately, Card only
  /// after the payment UI reports success. The confirmation page reads its
  /// `id` once this flips.
  final bool paymentConfirmed;

  @override
  List<Object?> get props => [isPlacingOrder, errorMessage, placedOrder, pendingPaymentClientSecret, paymentConfirmed];
}
