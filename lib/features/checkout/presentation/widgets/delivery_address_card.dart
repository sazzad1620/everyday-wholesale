import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/toast.dart';
import '../../../auth/presentation/bloc/account_bloc.dart';

/// Name is the real signed-in user's; the address line/phone are still
/// static mock text — real address management is a Phase 4 follow-up (see
/// PLAN.md), no saved-address data exists yet to show instead.
class DeliveryAddressCard extends StatelessWidget {
  const DeliveryAddressCard({super.key});

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
              Expanded(child: Text('checkout.delivery_address_title'.tr(), style: AppTextStyles.title)),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => showComingSoonToast(context, 'checkout.delivery_address_title'.tr()),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    'checkout.edit'.tr(),
                    style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            getIt<AccountBloc>().state.user?.name ?? 'account.guest_name'.tr(),
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            'checkout.mock_address_line'.tr(),
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            'checkout.mock_address_phone'.tr(),
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
