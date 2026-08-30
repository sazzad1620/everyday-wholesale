import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// The colored "Order ID" strip at the top of every order card/detail view —
/// shared by the customer order-history card, the admin order-list card, and
/// the order-detail page so all three read as the same visual element.
class OrderIdHeaderBar extends StatelessWidget {
  const OrderIdHeaderBar({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: AppColors.primary,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${'order_history.order_id'.tr()}  ', style: AppTextStyles.body.copyWith(color: Colors.white)),
            TextSpan(text: orderId, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
