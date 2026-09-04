import 'package:equatable/equatable.dart';

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class CheckoutOrderPlaceRequested extends CheckoutEvent {
  const CheckoutOrderPlaceRequested({
    required this.paymentMethod,
    required this.requiresCardPayment,
    required this.addressLine,
    required this.addressPhone,
    required this.addressReceiverName,
  });

  final String paymentMethod;

  /// False for Cash on Delivery, which places the order and finishes
  /// immediately, same as before Stripe existed. True for Card, which
  /// creates the order the same way but then continues into the real
  /// PaymentIntent + payment-UI flow before it's considered placed.
  final bool requiresCardPayment;
  final String addressLine;
  final String addressPhone;
  final String addressReceiverName;

  @override
  List<Object?> get props => [paymentMethod, requiresCardPayment, addressLine, addressPhone, addressReceiverName];
}

/// Dispatched by the page once it's presented the platform payment UI
/// (`PaymentSheet`/`CardField`) and the customer's card was confirmed.
class CheckoutPaymentConfirmed extends CheckoutEvent {
  const CheckoutPaymentConfirmed();
}

/// Dispatched by the page when the payment UI reports a real failure — the
/// order itself is left exactly as it was (still `unpaid`, not a duplicate),
/// so tapping "Place Order" again just retries payment against it.
class CheckoutPaymentFailed extends CheckoutEvent {
  const CheckoutPaymentFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Dispatched when the customer backs out of the payment UI without an
/// error — resets [CheckoutState.isPlacingOrder] silently (no error toast)
/// so "Place Order" is tappable again for the same order.
class CheckoutPaymentCanceled extends CheckoutEvent {
  const CheckoutPaymentCanceled();
}
