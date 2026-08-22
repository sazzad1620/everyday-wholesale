import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';

/// Custom bottom bar rather than Flutter's built-in [NavigationBar] because
/// "Category" doesn't map to a branch/page — it opens [MainShell]'s drawer
/// instead of switching the navigation shell, which [NavigationBar]'s
/// index-per-destination model can't express.
class MainBottomNavBar extends StatelessWidget {
  const MainBottomNavBar({
    super.key,
    required this.navigationShell,
    required this.onCategoryTap,
  });

  final StatefulNavigationShell navigationShell;
  final VoidCallback onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final currentBranchIndex = navigationShell.currentIndex;

    void goBranch(int index) {
      navigationShell.goBranch(index, initialLocation: index == currentBranchIndex);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'nav.home'.tr(),
                selected: currentBranchIndex == 0,
                onTap: () => goBranch(0),
              ),
              _NavItem(
                icon: Icons.category_outlined,
                selectedIcon: Icons.category_rounded,
                label: 'nav.category'.tr(),
                selected: false,
                onTap: onCategoryTap,
              ),
              _NavItem(
                icon: Icons.favorite_border_rounded,
                selectedIcon: Icons.favorite_rounded,
                label: 'nav.wishlist'.tr(),
                selected: currentBranchIndex == 1,
                onTap: () => goBranch(1),
              ),
              _NavItem(
                icon: Icons.shopping_cart_outlined,
                selectedIcon: Icons.shopping_cart_rounded,
                label: 'nav.cart'.tr(),
                selected: currentBranchIndex == 2,
                onTap: () => goBranch(2),
                badgeCount: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    Widget iconWidget = Icon(selected ? selectedIcon : icon, color: color, size: 23);
    if (badgeCount != null && badgeCount! > 0) {
      iconWidget = Badge(label: Text('$badgeCount'), child: iconWidget);
    }

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
