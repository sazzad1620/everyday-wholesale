import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../features/home/domain/entities/category_entity.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/toast.dart';
import 'category_nav_list.dart';

/// Persistent left nav shown instead of the hamburger drawer + bottom nav at
/// tablet/desktop widths (see [StandaloneShellScaffold]) — same
/// destinations as [MainMenuDrawer] + [CategoryDrawer] combined, just always
/// visible instead of behind two separate overlays. No separate "Home" entry
/// — the header's logo/wordmark already sits directly above this sidebar on
/// every page.
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({super.key, required this.categories});

  final List<CategoryEntity> categories;

  static const double width = 260;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(height: 1, color: AppColors.textSecondary.withValues(alpha: 0.15));

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.15))),
      ),
      // A Material ancestor, not just the Container above — ListTile paints
      // its background/ink splashes on the nearest Material, and the
      // decorated Container in between would otherwise hide them.
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 4),
              child: Text('drawer.category_title'.tr(), style: AppTextStyles.title.copyWith(fontSize: 15)),
            ),
            Expanded(
              child: CategoryNavList(
                categories: categories,
                tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              ),
            ),
            divider,
            _FooterLink(label: 'drawer.about'.tr(), onTap: () => showComingSoonToast(context, 'drawer.about'.tr())),
            _FooterLink(
              label: 'drawer.terms_privacy'.tr(),
              onTap: () => showComingSoonToast(context, 'drawer.terms_privacy'.tr()),
            ),
            _FooterLink(
              label: 'drawer.rate_app'.tr(),
              onTap: () => showComingSoonToast(context, 'drawer.rate_app'.tr()),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
      ),
    );
  }
}
