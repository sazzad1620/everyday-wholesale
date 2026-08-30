import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// The delivery address an order was placed with — a frozen snapshot on the
/// order itself (`addressLine`/`addressPhone`/`addressReceiverName`), not a
/// live read of the account's current saved address, so it stays correct
/// even if the customer's address changes later. Same card look as
/// checkout's `DeliveryAddressCard`, minus the edit action (an order's
/// address is fixed once placed).
class OrderAddressCard extends StatelessWidget {
  const OrderAddressCard({super.key, required this.addressLine, required this.phone, this.receiverName});

  final String addressLine;
  final String phone;

  /// Null for orders placed before this field existed — those already have
  /// the name baked into the front of [addressLine] itself, so there's
  /// nothing extra to show on its own line.
  final String? receiverName;

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
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text('checkout.delivery_address_title'.tr(), style: AppTextStyles.title),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (receiverName != null && receiverName!.isNotEmpty) ...[
            Text(receiverName!, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
          ],
          Text(phone, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(addressLine, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
