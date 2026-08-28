import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/asset_paths.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'app_search_bar.dart';

/// Menu + logo/wordmark + account icon, with the search bar folded into the
/// same block — the divider/shadow sits below the search bar, not between it
/// and the row above, so the whole thing reads as one header. Reused as-is
/// by Home, the category landing page, and product listings.
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onMenuTap,
                    icon: Icon(showBackButton ? Icons.arrow_back_rounded : Icons.menu_rounded),
                    color: AppColors.textPrimary,
                  ),
                  Image.asset(AssetPaths.logo, height: 30),
                  const SizedBox(width: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'header.brand_primary'.tr(),
                          style: GoogleFonts.oswald(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: 'header.brand_secondary'.tr(),
                          style: GoogleFonts.oswald(fontWeight: FontWeight.w300),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 18, letterSpacing: -0.2, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onAccountTap,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.person_outline_rounded, color: AppColors.textPrimary, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            if (showSearchBar) ...[
              const SizedBox(height: AppSpacing.sm),
              const AppSearchBar(),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
