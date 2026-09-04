import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';

abstract class PaymentRepository {
  /// Calls the `createPaymentIntent` Cloud Function for an already-placed
  /// order and returns its PaymentIntent `client_secret`, which the
  /// presentation layer hands to `flutter_stripe` to actually collect and
  /// confirm the card. The charge amount is never sent from here — the
  /// function reads it from the order doc itself server-side.
  Future<Either<Failure, String>> createPaymentIntent(String orderId);
}
