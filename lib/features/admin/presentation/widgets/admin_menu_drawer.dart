import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/di/injection_container.dart';
import '../../../../../config/routes/route_paths.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_spacing.dart';
import '../../../../../shared/theme/app_text_styles.dart';
import '../../../../../shared/widgets/navigation/drawer_header_bar.dart';
import '../../../auth/presentation/bloc/account_bloc.dart';
import '../../../auth/presentation/bloc/account_event.dart';

class AdminDestination {
  const AdminDestination({required this.icon, required this.selectedIcon, required this.label});

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Opened from the admin shell's header hamburger — replaces the old bottom
/// `NavigationBar` on mobile with the standard admin-panel sidebar pattern
/// instead (also reachable on desktop, alongside the always-visible
/// `NavigationRail`, for a consistent hamburger everywhere). Carries the
/// admin's name and Logout, which used to live in the old dedicated
/// `AdminHeader` — the header itself is now the plain shared [AppHeader], so
/// this drawer is where that identity/exit info moved, same shape as
/// [MainMenuDrawer] on the customer side.
class AdminMenuDrawer extends StatelessWidget {
  const AdminMenuDrawer({super.key, required this.selectedIndex, required this.onSelect, required this.destinations});

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<AdminDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final user = getIt<AccountBloc>().state.user;

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeaderBar(title: 'admin.panel_title'.tr()),
            if (user != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DrawerHeaderBar.contentLeftPadding,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Text(
                  user.name,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
            Divider(height: 1, color: AppColors.textSecondary.withValues(alpha: 0.15)),
            const SizedBox(height: AppSpacing.xs),
            for (var i = 0; i < destinations.length; i++)
              _AdminMenuTile(
                icon: i == selectedIndex ? destinations[i].selectedIcon : destinations[i].icon,
                label: destinations[i].label,
                selected: i == selectedIndex,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(i);
                },
              ),
            const Spacer(),
            Divider(height: 1, color: AppColors.textSecondary.withValues(alpha: 0.15)),
            _AdminMenuTile(
              icon: Icons.logout_rounded,
              label: 'admin.logout'.tr(),
              isDestructive: true,
              onTap: () {
                Navigator.of(context).pop();
                getIt<AccountBloc>().add(const AccountSignOutRequested());
                context.go(RoutePaths.home);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuTile extends StatelessWidget {
  const _AdminMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final iconColor = isDestructive ? AppColors.error : (selected ? AppColors.primary : AppColors.textSecondary);
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(DrawerHeaderBar.contentLeftPadding, 4, AppSpacing.md, 4),
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }
}
