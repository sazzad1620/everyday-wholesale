import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/toast.dart';
import '../../../support/presentation/pages/support_page.dart' show displayEmail, kSupportEmail;
import '../widgets/static_page_scaffold.dart';

/// Public "About Us" page — store story, address and contact, reached from
/// the drawer/sidebar footer link and the web [AppFooter].
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: kSupportEmail));
    if (!context.mounted) return;
    AppToast.show(context, 'support.email_copied'.tr(), type: ToastType.success);
  }

  Future<void> _openMaps() {
    final query = Uri.encodeComponent('footer.address'.tr());
    return launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaticPageScaffold(
      title: 'about.title'.tr(),
      children: [
        Text(
          'about.intro'.tr(),
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'about.body'.tr(),
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('about.visit_title'.tr(), style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        _InfoRow(icon: Icons.location_on_outlined, text: 'footer.address'.tr(), onTap: _openMaps),
        const SizedBox(height: AppSpacing.lg),
        Text('about.contact_title'.tr(), style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        _InfoRow(icon: Icons.mail_outline_rounded, text: displayEmail(kSupportEmail), onTap: () => _copyEmail(context)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, required this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
