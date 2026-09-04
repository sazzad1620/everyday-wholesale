import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/account_bloc.dart';
import '../../../auth/presentation/bloc/account_event.dart';

/// The 5 rows [AccountPage]'s own body renders (Edit Profile / Address /
/// Order History / My Reviews / Logout) — shared so [DesktopAccountNav] can
/// highlight the one the current page corresponds to. `null` on
/// [AccountPage] itself, which isn't one of its own 5 links.
enum AccountNavItem { editProfile, address, orderHistory, myReviews }

/// Persistent left nav for the account section (Account/Order History/
/// Address/Edit Profile/My Reviews) at tablet/desktop widths — reuses
/// [AccountPage]'s own 5 destinations so switching sections doesn't mean
/// going back to the hub page first. Mirrors [DesktopSidebar]'s shape
/// (fixed width, right border, `Material` ancestor for `ListTile` ink) but
/// swaps categories for account links.
class DesktopAccountNav extends StatelessWidget {
  const DesktopAccountNav({super.key, this.current});

  /// The section the page showing this nav belongs to, highlighted in the
  /// list — `null` on [AccountPage] itself (the hub, not one of its own
  /// links).
  final AccountNavItem? current;

  static const double width = 260;

  void _logout(BuildContext context) {
    getIt<AccountBloc>().add(const AccountSignOutRequested());
    context.go(RoutePaths.home);
  }

  /// `pushReplacement`, not `push` — tapping between sidebar links should
  /// swap the current account page, not keep stacking one on top of the
  /// last (which would make the back button step through every section
  /// visited instead of leaving the account area in one tap).
  void _navigate(BuildContext context, AccountNavItem item, String path) {
    if (item == current) return;
    context.pushReplacement(path);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                4,
              ),
              child: Text(
                'account.title'.tr(),
                style: AppTextStyles.title.copyWith(fontSize: 15),
              ),
            ),
            _NavTile(
              icon: Icons.edit_outlined,
              label: 'account.edit_profile'.tr(),
              selected: current == AccountNavItem.editProfile,
              onTap: () => _navigate(
                context,
                AccountNavItem.editProfile,
                RoutePaths.editProfile,
              ),
            ),
            _NavTile(
              icon: Icons.location_on_outlined,
              label: 'account.address'.tr(),
              selected: current == AccountNavItem.address,
              onTap: () => _navigate(
                context,
                AccountNavItem.address,
                RoutePaths.accountAddress,
              ),
            ),
            _NavTile(
              icon: Icons.receipt_long_outlined,
              label: 'account.order_history'.tr(),
              selected: current == AccountNavItem.orderHistory,
              onTap: () => _navigate(
                context,
                AccountNavItem.orderHistory,
                RoutePaths.orderHistory,
              ),
            ),
            _NavTile(
              icon: Icons.star_outline_rounded,
              label: 'account.my_reviews'.tr(),
              selected: current == AccountNavItem.myReviews,
              onTap: () => _navigate(
                context,
                AccountNavItem.myReviews,
                RoutePaths.myReviews,
              ),
            ),
            Divider(
              height: 1,
              color: AppColors.textSecondary.withValues(alpha: 0.15),
            ),
            _NavTile(
              icon: Icons.logout_rounded,
              label: 'account.logout'.tr(),
              selected: false,
              isDestructive: true,
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.error
        : (selected ? AppColors.primary : AppColors.textPrimary);

    // Material itself (not a plain colored Container) carries the
    // selected-row tint — ListTile paints its background/ink splashes on
    // the nearest Material, and a colored Container in between would
    // otherwise hide them (see DesktopSidebar's matching fix).
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        leading: Icon(
          icon,
          color: isDestructive
              ? AppColors.error
              : (selected ? AppColors.primary : AppColors.textSecondary),
        ),
        title: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: color,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
