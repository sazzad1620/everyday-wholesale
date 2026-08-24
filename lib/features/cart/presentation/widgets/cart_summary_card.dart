import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/cart_totals.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/buttons/secondary_button.dart';
import '../../../../shared/widgets/cart_totals_breakdown.dart';

/// The totals breakdown + checkout actions, shown below [CartVoucherCard].
class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard({super.key, required this.itemTotal, required this.onCheckout, required this.onReturnToShopping});

  final int itemTotal;
  final VoidCallback onCheckout;
  final VoidCallback onReturnToShopping;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('cart.cart_total'.tr(), style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.md),
          CartTotalsBreakdown(totals: CartTotals.compute(itemTotal)),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: 'cart.checkout'.tr(), onTap: onCheckout),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(label: 'cart.return_to_shopping'.tr(), onTap: onReturnToShopping),
        ],
      ),
    );
  }
}
