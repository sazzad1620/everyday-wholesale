import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../widgets/static_page_scaffold.dart';

/// Draft privacy policy — covers what the app actually does (Firebase auth
/// + Firestore, Stripe for payments, no card data stored locally). Written
/// as a reasonable starting point; have it reviewed before relying on it for
/// compliance (e.g. Japan's APPI).
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StaticPageScaffold(
      title: 'legal.privacy_title'.tr(),
      children: [
        Text(
          'legal.privacy_updated'.tr(),
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'legal.privacy_intro'.tr(),
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: AppSpacing.lg),
        LegalSection(title: 'legal.privacy_collect_title'.tr(), body: 'legal.privacy_collect_body'.tr()),
        LegalSection(title: 'legal.privacy_use_title'.tr(), body: 'legal.privacy_use_body'.tr()),
        LegalSection(title: 'legal.privacy_sharing_title'.tr(), body: 'legal.privacy_sharing_body'.tr()),
        LegalSection(title: 'legal.privacy_retention_title'.tr(), body: 'legal.privacy_retention_body'.tr()),
        LegalSection(title: 'legal.privacy_rights_title'.tr(), body: 'legal.privacy_rights_body'.tr()),
        LegalSection(title: 'legal.privacy_contact_title'.tr(), body: 'legal.privacy_contact_body'.tr()),
      ],
    );
  }
}
