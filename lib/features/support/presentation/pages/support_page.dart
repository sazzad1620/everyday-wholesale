import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/toast.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../account/presentation/pages/account_page.dart';

const String kSupportEmail = 'everydaywholesale.jp@gmail.com';

/// Public customer-support page (also the "Customer support URL" registered
/// with Stripe, so it must render for signed-out visitors and when opened
/// directly by URL). Pushed on the root navigator, outside the shell, like the
/// account pages.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              showSearchBar: false,
              showBackButton: true,
              // A direct/reloaded /support URL has nothing to pop back to.
              onMenuTap: () => context.canPop() ? context.pop() : context.go(RoutePaths.home),
              onAccountTap: () => openAccountMenu(context),
            ),
            const Expanded(child: _SupportBody()),
          ],
        ),
      ),
    );
  }
}

class _SupportBody extends StatelessWidget {
  const _SupportBody();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md) + EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
          children: [
            Text('support.title'.tr(), style: AppTextStyles.headline),
            const SizedBox(height: AppSpacing.sm),
            Text('support.intro'.tr(), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            const _EmailCard(),
            const SizedBox(height: AppSpacing.md),
            _InfoSection(
              icon: Icons.schedule_rounded,
              title: 'support.response_title'.tr(),
              body: 'support.response_body'.tr(),
            ),
            _InfoSection(
              icon: Icons.receipt_long_outlined,
              title: 'support.orders_title'.tr(),
              body: 'support.orders_body'.tr(),
            ),
            _InfoSection(
              icon: Icons.undo_rounded,
              title: 'support.refunds_title'.tr(),
              body: 'support.refunds_body'.tr(),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'support.business_name'.tr(),
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailCard extends StatelessWidget {
  const _EmailCard();

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: kSupportEmail));
    if (!context.mounted) return;
    AppToast.show(context, 'support.email_copied'.tr(), type: ToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _copy(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.mail_outline_rounded, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('support.email_title'.tr(), style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.xs),
                    SelectableText(
                      kSupportEmail,
                      style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'support.email_hint'.tr(),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.copy_rounded, size: 20, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.xs),
                Text(body, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
