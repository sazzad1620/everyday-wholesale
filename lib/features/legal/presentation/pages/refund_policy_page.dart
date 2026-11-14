import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../widgets/static_page_scaffold.dart';

/// Full refund policy — expands on the short version shown in
/// `SupportPage`, with an explicit note on perishable items (meat/produce),
/// which food-safety rules keep non-returnable.
class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StaticPageScaffold(
      title: 'legal.refunds_title'.tr(),
      children: [
        Text(
          'legal.refunds_updated'.tr(),
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'legal.refunds_intro'.tr(),
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: AppSpacing.lg),
        LegalSection(title: 'legal.refunds_eligibility_title'.tr(), body: 'legal.refunds_eligibility_body'.tr()),
        LegalSection(title: 'legal.refunds_process_title'.tr(), body: 'legal.refunds_process_body'.tr()),
        LegalSection(
          title: 'legal.refunds_non_refundable_title'.tr(),
          body: 'legal.refunds_non_refundable_body'.tr(),
        ),
        LegalSection(title: 'legal.refunds_contact_title'.tr(), body: 'legal.refunds_contact_body'.tr()),
      ],
    );
  }
}
