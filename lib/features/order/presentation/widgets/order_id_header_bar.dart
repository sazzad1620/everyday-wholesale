import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/toast.dart';

/// The colored "Order ID" strip at the top of every order card/detail view —
/// shared by the customer order-history card, the admin order-list card, and
/// the order-detail page so all three read as the same visual element. The
/// copy icon is a small affordance (rather than the bigger tap-to-copy row
/// style used elsewhere) since this also has to sit comfortably in a list
/// card, not just the detail page.
class OrderIdHeaderBar extends StatelessWidget {
  const OrderIdHeaderBar({super.key, required this.orderId});

  final String orderId;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: orderId));
    if (context.mounted) AppToast.show(context, 'common.copied_to_clipboard'.tr(), type: ToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: AppColors.primary,
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${'order_history.order_id'.tr()}  ', style: AppTextStyles.body.copyWith(color: Colors.white)),
                  TextSpan(text: orderId, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          InkWell(
            onTap: () => _copy(context),
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.copy_rounded, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
