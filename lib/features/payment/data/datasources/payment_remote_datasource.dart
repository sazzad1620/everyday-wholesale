import 'package:cloud_functions/cloud_functions.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';

abstract class PaymentRemoteDatasource {
  Future<String> createPaymentIntent(String orderId);
}

@LazySingleton(as: PaymentRemoteDatasource)
class PaymentRemoteDatasourceImpl implements PaymentRemoteDatasource {
  PaymentRemoteDatasourceImpl(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<String> createPaymentIntent(String orderId) async {
    try {
      // Same reasoning as `OrderRemoteDatasourceImpl.placeOrder`'s timeout —
      // a hung network call here would leave the payment sheet's loading
      // state spinning forever instead of failing with something the
      // customer can act on.
      final result = await _functions
          .httpsCallable('createPaymentIntent')
          .call<Map<String, dynamic>>({'orderId': orderId})
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw const ServerException('errors.payment_start_timeout'),
          );

      final clientSecret = result.data['clientSecret'] as String?;
      if (clientSecret == null || clientSecret.isEmpty) {
        throw const ServerException('errors.payment_start_failed');
      }
      return clientSecret;
    } on FirebaseFunctionsException catch (e) {
      throw ServerException(_keyForCode(e.code));
    }
  }

  /// The function's own error text is developer-facing English (see
  /// `functions/src/index.ts`), so it never reaches the customer — the code
  /// picks the translated copy instead.
  String _keyForCode(String code) => switch (code) {
    'unauthenticated' => 'errors.sign_in_required_place_order',
    'not-found' => 'errors.not_found',
    'deadline-exceeded' || 'unavailable' => 'errors.payment_start_timeout',
    _ => 'errors.payment_start_failed',
  };
}
