import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../order/domain/entities/order_entity.dart';

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({this.order, super.key});

  final OrderEntity? order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 56),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('checkout.confirmation_title'.tr(), style: AppTextStyles.headline, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'checkout.confirmation_message'.tr(),
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (order != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'checkout.confirmation_order_id'.tr(namedArgs: {'id': order!.id}),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: 'checkout.continue_shopping'.tr(), onTap: () => context.go(RoutePaths.home)),
            ],
          ),
        ),
      ),
    );
  }
}
