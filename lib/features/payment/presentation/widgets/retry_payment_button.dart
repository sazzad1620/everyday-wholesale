import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../shared/utils/toast.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../domain/entities/payment_confirmation_result.dart';
import '../../domain/usecases/create_payment_intent_usecase.dart';
import '../payment_confirmation.dart';

/// Re-runs the create-PaymentIntent → confirm-payment flow against an
/// existing order — shown only where `paymentStatus == PaymentStatus.failed`
/// (never plain `unpaid`, which can just mean "still processing": offering
/// retry there risks the customer starting a second payment while the first
/// is still resolving, a double-charge race). Self-contained (its own
/// loading state and error toasts) since it's a one-shot action, not
/// something that needs a dedicated bloc.
class RetryPaymentButton extends StatefulWidget {
  const RetryPaymentButton({
    super.key,
    required this.orderId,
    required this.onSucceeded,
  });

  final String orderId;

  /// Called once the payment is confirmed — the caller decides what to show
  /// next (e.g. navigate to the order-confirmation page's live status view).
  final VoidCallback onSucceeded;

  @override
  State<RetryPaymentButton> createState() => _RetryPaymentButtonState();
}

class _RetryPaymentButtonState extends State<RetryPaymentButton> {
  bool _isRetrying = false;

  Future<void> _retry() async {
    setState(() => _isRetrying = true);

    final intentResult = await getIt<CreatePaymentIntentUseCase>()(
      widget.orderId,
    );
    final clientSecret = intentResult.match((failure) {
      if (mounted) {
        AppToast.show(context, failure.message, type: ToastType.error);
      }
      return null;
    }, (secret) => secret);

    if (clientSecret == null) {
      if (mounted) setState(() => _isRetrying = false);
      return;
    }
    if (!mounted) return;

    final result = await confirmCardPayment(
      context: context,
      clientSecret: clientSecret,
    );
    if (!mounted) return;
    setState(() => _isRetrying = false);

    switch (result) {
      case PaymentConfirmationSucceeded():
        widget.onSucceeded();
      case PaymentConfirmationCanceled():
        break;
      case PaymentConfirmationFailed(:final message):
        AppToast.show(context, message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: 'order_history.retry_payment'.tr(),
      icon: Icons.refresh_rounded,
      isLoading: _isRetrying,
      onTap: _retry,
    );
  }
}
