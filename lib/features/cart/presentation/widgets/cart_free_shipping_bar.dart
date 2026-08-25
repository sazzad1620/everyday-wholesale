import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/pricing_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// Live progress toward [PricingConstants.freeDeliveryThresholdYen] — shown
/// above the cart's item list so it updates as items/quantities change and
/// stays visible without scrolling. Collapses to an "unlocked" state once
/// [itemTotal] clears the threshold.
class CartFreeShippingBar extends StatelessWidget {
  const CartFreeShippingBar({super.key, required this.itemTotal});

  final int itemTotal;

  @override
  Widget build(BuildContext context) {
    final remaining = PricingConstants.freeDeliveryThresholdYen - itemTotal;
    final isUnlocked = remaining <= 0;
    final progress = (itemTotal / PricingConstants.freeDeliveryThresholdYen).clamp(0.0, 1.0);

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
          Row(
            children: [
              Icon(
                isUnlocked ? Icons.check_circle_outline : Icons.local_shipping_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isUnlocked
                      ? 'cart.free_shipping_unlocked'.tr()
                      : 'cart.free_shipping_progress'.tr(namedArgs: {'amount': formatYen(remaining)}),
                  style: AppTextStyles.caption,
                ),
              ),
              if (!isUnlocked) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    formatYen(remaining),
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
