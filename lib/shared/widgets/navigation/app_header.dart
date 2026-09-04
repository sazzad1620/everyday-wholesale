import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/di/injection_container.dart';
import '../../../config/routes/route_paths.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/utils/responsive/breakpoints.dart';
import '../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../features/cart/presentation/bloc/cart_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'app_search_bar.dart';

/// Menu + logo/wordmark + account icon, with the search bar folded into the
/// same block — the divider/shadow sits below the search bar, not between it
/// and the row above, so the whole thing reads as one header. Reused as-is
/// by Home, the category landing page, and product listings.
///
/// At width >= [AppBreakpoints.mobile] this collapses to a single row —
/// logo, search bar, then Wishlist/Cart/Account — instead of phone's
/// logo-row-then-search-row stack, since there's width to spare and a
/// second row just wastes vertical space on a wide screen.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.onMenuTap,
    required this.onAccountTap,
    this.showSearchBar = true,
    this.showBackButton = false,
  });

  /// Opens [MainMenuDrawer] normally; on pages where [showBackButton] is
  /// true, this is wired to pop instead — same slot, different action, so
  /// call sites don't need a second callback.
  final VoidCallback onMenuTap;
  final VoidCallback onAccountTap;

  /// Hidden on pages that don't need product search (e.g. the account page).
  final bool showSearchBar;

  /// Shows a back arrow instead of the hamburger — for pages like the
  /// account and order-history pages that are drilled into rather than
  /// switched to, where "go back" makes more sense than opening the menu.
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    // Tablet/desktop drops the hamburger (the persistent [DesktopSidebar]
    // replaces it — see [StandaloneShellScaffold]) unless this page still
    // needs a back arrow, caps the search bar's width instead of letting it
    // stretch full-bleed, and surfaces Wishlist/Cart/Account as header
    // actions — Wishlist/Cart stand in for the bottom nav's equivalents,
    // which don't render at this width.
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.15))),
        // Tight on purpose — a wider/softer blur here reads as a grey wash
        // on an otherwise all-white page, not as a shadow.
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 3, offset: const Offset(0, 1)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: isWide ? _WideHeaderRow(header: this) : _NarrowHeaderColumn(header: this),
      ),
    );
  }
}

/// Phone layout: logo/menu/account row, then the search bar below it —
/// unchanged from before the tablet/desktop split existed.
class _NarrowHeaderColumn extends StatelessWidget {
  const _NarrowHeaderColumn({required this.header});

  final AppHeader header;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
          child: Row(
            children: [
              IconButton(
                onPressed: header.onMenuTap,
                icon: Icon(header.showBackButton ? Icons.arrow_back_rounded : Icons.menu_rounded),
                color: AppColors.textPrimary,
              ),
              const _BrandMark(),
              const Spacer(),
              InkWell(
                onTap: header.onAccountTap,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.person_outline_rounded, color: AppColors.textPrimary, size: 22),
                ),
              ),
            ],
          ),
        ),
        if (header.showSearchBar) ...[const SizedBox(height: AppSpacing.sm), const AppSearchBar()],
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// Tablet/desktop layout: everything on one line — back arrow (only on
/// pages that need it; no hamburger otherwise, [DesktopSidebar] covers
/// that), logo, search bar, then Wishlist/Cart/Account as matching
/// icon-over-label actions so none of the three reads as smaller than the
/// others.
class _WideHeaderRow extends StatelessWidget {
  const _WideHeaderRow({required this.header});

  final AppHeader header;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          if (header.showBackButton)
            IconButton(
              onPressed: header.onMenuTap,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
            )
          else
            const SizedBox(width: AppSpacing.sm),
          const _BrandMark(),
          const SizedBox(width: AppSpacing.lg),
          if (header.showSearchBar)
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: const AppSearchBar(),
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: AppSpacing.md),
          _HeaderNavAction(
            icon: Icons.favorite_border_rounded,
            label: 'nav.wishlist'.tr(),
            onTap: () => context.go(RoutePaths.wishlist),
          ),
          const SizedBox(width: AppSpacing.xs),
          BlocBuilder<CartBloc, CartState>(
            bloc: getIt<CartBloc>(),
            builder: (context, state) => _HeaderNavAction(
              icon: Icons.shopping_cart_outlined,
              label: 'nav.cart'.tr(),
              badgeCount: state.itemCount,
              onTap: () => context.go(RoutePaths.cart),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _HeaderNavAction(
            icon: Icons.person_outline_rounded,
            label: 'nav.account'.tr(),
            onTap: header.onAccountTap,
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(AssetPaths.logo, height: 30),
        const SizedBox(width: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'header.brand_primary'.tr(), style: GoogleFonts.oswald(fontWeight: FontWeight.w600)),
              const TextSpan(text: ' '),
              TextSpan(text: 'header.brand_secondary'.tr(), style: GoogleFonts.oswald(fontWeight: FontWeight.w300)),
            ],
          ),
          style: const TextStyle(fontSize: 18, letterSpacing: -0.2, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

/// Wishlist/Cart/Account header entry — icon-over-label so all three share
/// the same size and weight (a bare icon next to labeled ones reads as
/// smaller even at equal icon size).
class _HeaderNavAction extends StatelessWidget {
  const _HeaderNavAction({required this.icon, required this.label, required this.onTap, this.badgeCount});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(icon, color: AppColors.textPrimary, size: 22);
    if (badgeCount != null && badgeCount! > 0) {
      iconWidget = Badge(label: Text('$badgeCount'), child: iconWidget);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
