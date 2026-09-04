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
            onTimeout: () => throw const ServerException(
              'Could not start the payment. Please check your internet connection and try again.',
            ),
          );

      final clientSecret = result.data['clientSecret'] as String?;
      if (clientSecret == null || clientSecret.isEmpty) {
        throw const ServerException('Could not start the payment. Please try again.');
      }
      return clientSecret;
    } on FirebaseFunctionsException catch (e) {
      throw ServerException(e.message ?? 'Could not start the payment. Please try again.');
    }
  }
}
