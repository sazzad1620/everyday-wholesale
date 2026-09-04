import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../shared/widgets/dialogs/dialog_shell.dart';
import '../domain/entities/payment_confirmation_result.dart';
import 'widgets/card_payment_sheet.dart';

/// Presents Stripe's platform payment UI for [clientSecret] and reports the
/// outcome. Mobile uses the native `PaymentSheet`; the web SDK doesn't
/// support it, so web falls back to an in-app [CardPaymentSheet] built on
/// `CardField` + `confirmPayment`.
Future<PaymentConfirmationResult> confirmCardPayment({required BuildContext context, required String clientSecret}) {
  return kIsWeb ? _confirmWithCardField(context, clientSecret) : _confirmWithPaymentSheet(clientSecret);
}

Future<PaymentConfirmationResult> _confirmWithPaymentSheet(String clientSecret) async {
  try {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Everyday Wholesale',
      ),
    );
    await Stripe.instance.presentPaymentSheet();
    return const PaymentConfirmationSucceeded();
  } on StripeException catch (e) {
    if (e.error.code == FailureCode.Canceled) return const PaymentConfirmationCanceled();
    return PaymentConfirmationFailed(e.error.localizedMessage ?? e.error.message ?? 'payment.generic_error'.tr());
  } catch (_) {
    return PaymentConfirmationFailed('payment.generic_error'.tr());
  }
}

Future<PaymentConfirmationResult> _confirmWithCardField(BuildContext context, String clientSecret) async {
  final result = await showBlurredBottomSheet<PaymentConfirmationResult>(
    context: context,
    builder: (context) => CardPaymentSheet(clientSecret: clientSecret),
  );
  return result ?? const PaymentConfirmationCanceled();
}
