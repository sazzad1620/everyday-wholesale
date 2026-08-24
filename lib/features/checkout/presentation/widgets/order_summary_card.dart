import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/cart_totals.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/cart_totals_breakdown.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';

/// A compact, read-only recap of what's in the cart (no quantity/remove
/// controls — that's what going back to the cart is for), followed by the
/// same breakdown the cart page shows, so the numbers a customer reviews at
/// checkout are guaranteed to match what they saw there.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.items, required this.itemTotal});

  final List<CartItemEntity> items;
  final int itemTotal;

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
          Text('checkout.order_summary_title'.tr(), style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.product.name} x${item.quantity}',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(formatYen(item.lineTotal), style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: AppColors.inputFill),
          ),
          CartTotalsBreakdown(totals: CartTotals.compute(itemTotal)),
        ],
      ),
    );
  }
}
