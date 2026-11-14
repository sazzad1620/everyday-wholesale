import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../widgets/static_page_scaffold.dart';

/// Draft terms & conditions — a reasonable starting point covering orders,
/// payment, delivery and accounts. Have it reviewed before relying on it.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StaticPageScaffold(
      title: 'legal.terms_title'.tr(),
      children: [
        Text(
          'legal.terms_updated'.tr(),
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'legal.terms_intro'.tr(),
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: AppSpacing.lg),
        LegalSection(title: 'legal.terms_orders_title'.tr(), body: 'legal.terms_orders_body'.tr()),
        LegalSection(title: 'legal.terms_payment_title'.tr(), body: 'legal.terms_payment_body'.tr()),
        LegalSection(title: 'legal.terms_delivery_title'.tr(), body: 'legal.terms_delivery_body'.tr()),
        LegalSection(title: 'legal.terms_accounts_title'.tr(), body: 'legal.terms_accounts_body'.tr()),
        LegalSection(title: 'legal.terms_conduct_title'.tr(), body: 'legal.terms_conduct_body'.tr()),
        LegalSection(title: 'legal.terms_changes_title'.tr(), body: 'legal.terms_changes_body'.tr()),
      ],
    );
  }
}
