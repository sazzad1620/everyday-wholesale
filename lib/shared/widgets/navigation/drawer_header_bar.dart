import 'package:flutter/material.dart';

import '../../../core/constants/asset_paths.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Logo + title row shared by every drawer, separated from the content
/// below by the same soft shadow [AppHeader] uses — no hard divider line.
class DrawerHeaderBar extends StatelessWidget {
  const DrawerHeaderBar({super.key, required this.title});

  final String title;

  /// Left inset the logo starts at — content lists below (see
  /// [CategoryDrawer], [MainMenuDrawer]) use this too so their rows line up
  /// with where the logo starts, not the tighter default [AppSpacing.md].
  static const double contentLeftPadding = AppSpacing.md + AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.15))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 3, offset: const Offset(0, 1)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(contentLeftPadding, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
        child: Row(
          children: [
            Image.asset(AssetPaths.logo, height: 30),
            const SizedBox(width: AppSpacing.sm),
            Text(title, style: AppTextStyles.title),
          ],
        ),
      ),
    );
  }
}
