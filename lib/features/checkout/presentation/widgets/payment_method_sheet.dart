import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/dialogs/dialog_shell.dart';

enum PaymentMethodOption { cash, card }

extension PaymentMethodOptionLabel on PaymentMethodOption {
  /// The string sent to [CheckoutOrderPlaceRequested.paymentMethod] and
  /// shown wherever the chosen method is displayed back to the user.
  String label() => switch (this) {
    PaymentMethodOption.cash => 'checkout.payment_method_cash'.tr(),
    PaymentMethodOption.card => 'checkout.payment_method_card'.tr(),
  };

  IconData get icon => switch (this) {
    PaymentMethodOption.cash => Icons.payments_outlined,
    PaymentMethodOption.card => Icons.credit_card_outlined,
  };
}

/// Bottom sheet for picking Cash-on-Delivery vs. Card — tapping an option
/// selects it and immediately closes the sheet (no separate "Confirm" step,
/// same one-tap-to-choose pattern as a system picker). Returns `null` if
/// dismissed without picking, in which case the caller leaves the previous
/// selection (if any) untouched.
Future<PaymentMethodOption?> showPaymentMethodSheet(BuildContext context, {PaymentMethodOption? selected}) {
  return showBlurredBottomSheet<PaymentMethodOption>(
    context: context,
    builder: (context) => _PaymentMethodSheet(selected: selected),
  );
}

class _PaymentMethodSheet extends StatelessWidget {
  const _PaymentMethodSheet({required this.selected});

  final PaymentMethodOption? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  const SizedBox(width: 30),
                  Expanded(
                    child: Text(
                      'checkout.choose_payment_method'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.title,
                    ),
                  ),
                  DialogCloseButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: AppColors.textSecondary.withValues(alpha: 0.15)),
            for (final option in PaymentMethodOption.values) ...[
              _PaymentOptionTile(
                option: option,
                selected: selected == option,
                onTap: () => Navigator.of(context).pop(option),
              ),
              if (option != PaymentMethodOption.values.last)
                Divider(height: 1, color: AppColors.textSecondary.withValues(alpha: 0.15)),
            ],
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({required this.option, required this.selected, required this.onTap});

  final PaymentMethodOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.4),
              size: 22,
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(option.icon, color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(option.label(), style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}
