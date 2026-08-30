import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/account_bloc.dart';

/// Reads the signed-in user's one saved address straight off [AccountBloc]
/// — no local state of its own, so it always reflects whatever Account >
/// Address (or this card's own "Edit" link, same destination) last saved.
class DeliveryAddressCard extends StatelessWidget {
  const DeliveryAddressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final address = getIt<AccountBloc>().state.user?.address;

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
                onTap: () => context.push(RoutePaths.accountAddress),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    address == null ? 'checkout.add_address'.tr() : 'checkout.edit'.tr(),
                    style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (address == null)
            Text(
              'checkout.no_address_saved'.tr(),
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            )
          else ...[
            Text(address.receiverName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(address.phoneNumber, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(address.formattedLine, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
