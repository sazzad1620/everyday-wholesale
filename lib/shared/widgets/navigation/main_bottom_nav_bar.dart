import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/di/injection_container.dart';
import '../../../config/routes/route_paths.dart';
import '../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../features/cart/presentation/bloc/cart_state.dart';
import '../../theme/app_colors.dart';

/// Floating, fully rounded bottom bar (foodpanda style). The page runs
/// behind it ([StandaloneShellScaffold] sets `extendBody`), so content stays
/// visible around the pill's rounded corners and in the margins beside it.
///
/// Below the pill's middle a light fade (transparent → mostly background)
/// softens content passing under the bar and the system inset (gesture bar /
/// 3-button bar / iOS home indicator) without hiding it completely. Nothing
/// is painted above the pill. A gradient rather than a real backdrop blur:
/// it looks the same here and costs nothing to redraw while scrolling (a
/// blur is re-rendered every frame, which is noticeably expensive on web).
///
/// Pages add `MediaQuery.paddingOf(context).bottom` (this bar's height, as
/// reported by the Scaffold) to their scroll views so the last item still
/// scrolls clear of it.
///
/// Custom rather than Flutter's [NavigationBar] because "Category" doesn't
/// map to a branch/page — it opens [MainShell]'s drawer instead of switching
/// the navigation shell, which [NavigationBar]'s index-per-destination model
/// can't express.
class MainBottomNavBar extends StatelessWidget {
  const MainBottomNavBar({
    super.key,
    required this.navigationShell,
    required this.onCategoryTap,
  });

  /// Null on full-screen pages pushed on the root navigator (e.g. the
  /// account and order-history pages) — they aren't one of the shell's
  /// branches, so nothing renders selected and taps fall back to
  /// `context.go` instead of [StatefulNavigationShell.goBranch].
  final StatefulNavigationShell? navigationShell;
  final VoidCallback onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final currentBranchIndex = navigationShell?.currentIndex ?? -1;
    // Narrow phones (e.g. 320–359pt wide) get tighter margins so four
    // labels still fit comfortably.
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 360;
    // Short screens (a phone browser in landscape, split screen) get a
    // slimmer pill so it doesn't take a big share of the height.
    final short = size.height < 480;

    void goBranch(int index, String path) {
      final shell = navigationShell;
      if (shell != null) {
        shell.goBranch(index, initialLocation: index == currentBranchIndex);
      } else {
        context.go(path);
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Downward-only fade: fully transparent down to about the pill's
        // middle, then towards the page background, so content under the
        // lower half of the pill and the system bar area stays faintly visible.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0),
                    AppColors.background.withValues(alpha: 0),
                    AppColors.background.withValues(alpha: 0.7),
                    AppColors.background.withValues(alpha: 0.85),
                  ],
                  stops: const [0, 0.4, 0.75, 1],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          // Keeps the pill off the screen edge on devices with no system
          // inset (e.g. phone browsers, older Androids with a black nav bar).
          // Left/right insets (a landscape 3-button bar, notches) apply too.
          minimum: EdgeInsets.only(bottom: short ? 6 : 10),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
            // Centred and capped so it stays a compact pill rather than a
            // full-width strip on a landscape phone browser.
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8)),
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(short ? 4 : 6),
                    child: Row(
                      children: [
                        _NavItem(
                          icon: Icons.home_outlined,
                          selectedIcon: Icons.home_rounded,
                          label: 'nav.home'.tr(),
                          selected: currentBranchIndex == 0,
                          compact: compact,
                          short: short,
                          onTap: () => goBranch(0, RoutePaths.home),
                        ),
                        _NavItem(
                          icon: Icons.category_outlined,
                          selectedIcon: Icons.category_rounded,
                          label: 'nav.category'.tr(),
                          selected: false,
                          compact: compact,
                          short: short,
                          onTap: onCategoryTap,
                        ),
                        _NavItem(
                          icon: Icons.favorite_border_rounded,
                          selectedIcon: Icons.favorite_rounded,
                          label: 'nav.wishlist'.tr(),
                          selected: currentBranchIndex == 1,
                          compact: compact,
                          short: short,
                          onTap: () => goBranch(1, RoutePaths.wishlist),
                        ),
                        BlocBuilder<CartBloc, CartState>(
                          bloc: getIt<CartBloc>(),
                          buildWhen: (previous, current) => previous.itemCount != current.itemCount,
                          builder: (context, cartState) => _NavItem(
                            icon: Icons.shopping_cart_outlined,
                            selectedIcon: Icons.shopping_cart_rounded,
                            label: 'nav.cart'.tr(),
                            selected: currentBranchIndex == 2,
                            compact: compact,
                            short: short,
                            onTap: () => goBranch(2, RoutePaths.cart),
                            badgeCount: cartState.itemCount,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.short,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool compact;
  final bool short;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    Widget iconWidget = Icon(selected ? selectedIcon : icon, color: color, size: 24);
    if (badgeCount != null && badgeCount! > 0) {
      iconWidget = Badge(label: Text('$badgeCount'), child: iconWidget);
    }

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(vertical: short ? 4 : 7),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                SizedBox(height: short ? 1 : 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 10.5 : 11.5,
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
