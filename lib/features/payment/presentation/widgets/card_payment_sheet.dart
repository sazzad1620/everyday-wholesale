import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/dialogs/dialog_shell.dart';
import '../../domain/entities/payment_confirmation_result.dart';

/// Web-only fallback for the native `PaymentSheet` (unsupported by
/// `flutter_stripe`'s web SDK) — a `CardField` plus a Pay button, confirming
/// the PaymentIntent directly via `Stripe.instance.confirmPayment`. Pops
/// with a [PaymentConfirmationResult]; a plain dismiss (tapping the
/// backdrop) resolves to `null`, which the caller treats as canceled.
class CardPaymentSheet extends StatefulWidget {
  const CardPaymentSheet({super.key, required this.clientSecret});

  final String clientSecret;

  @override
  State<CardPaymentSheet> createState() => _CardPaymentSheetState();
}

class _CardPaymentSheetState extends State<CardPaymentSheet> {
  bool _cardComplete = false;
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _pay() async {
    if (!_cardComplete || _isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: widget.clientSecret,
        data: const PaymentMethodParams.card(paymentMethodData: PaymentMethodData()),
      );
      if (mounted) Navigator.of(context).pop(const PaymentConfirmationSucceeded());
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        if (mounted) Navigator.of(context).pop(const PaymentConfirmationCanceled());
        return;
      }
      setState(() {
        _isProcessing = false;
        _errorMessage = e.error.localizedMessage ?? e.error.message ?? 'payment.generic_error'.tr();
      });
    } catch (_) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'payment.generic_error'.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Material(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 30),
                    Expanded(
                      child: Text(
                        'payment.card_details_title'.tr(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.title,
                      ),
                    ),
                    DialogCloseButton(onTap: _isProcessing ? () {} : () => Navigator.of(context).pop()),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CardField(
                    enablePostalCode: true,
                    onCardChanged: (details) => setState(() => _cardComplete = details?.complete ?? false),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_errorMessage!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                ],
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(label: 'payment.pay_now'.tr(), isLoading: _isProcessing, onTap: _pay),
                const SizedBox(height: AppSpacing.xs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
