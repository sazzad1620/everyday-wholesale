/// Outcome of presenting the platform payment UI for a PaymentIntent —
/// shared between `payment_confirmation.dart` (which produces it) and
/// `CardPaymentSheet` (which, on web, is the one actually producing it).
sealed class PaymentConfirmationResult {
  const PaymentConfirmationResult();
}

class PaymentConfirmationSucceeded extends PaymentConfirmationResult {
  const PaymentConfirmationSucceeded();
}

/// The customer backed out of the payment UI — the order stays unpaid but
/// otherwise untouched, so retrying just reopens payment for the same order.
class PaymentConfirmationCanceled extends PaymentConfirmationResult {
  const PaymentConfirmationCanceled();
}

class PaymentConfirmationFailed extends PaymentConfirmationResult {
  const PaymentConfirmationFailed(this.message);

  final String message;
}
