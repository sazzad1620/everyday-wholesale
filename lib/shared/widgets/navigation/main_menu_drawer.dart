import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/snack_utils.dart';
import 'drawer_header_bar.dart';

/// Opened from the hamburger menu icon on every page's [AppHeader] — always
/// the same drawer regardless of which page/tab you're on. Distinct from
/// [CategoryDrawer], which only opens from the bottom nav's "Category" item.
/// Just About/Contact for now; more entries land here later.
class MainMenuDrawer extends StatelessWidget {
  const MainMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeaderBar(title: 'drawer.main_menu_title'.tr()),
            const SizedBox(height: AppSpacing.xs),
            _MenuTile(
              icon: Icons.info_outline_rounded,
              label: 'drawer.about'.tr(),
              onTap: () => showComingSoonSnackBar(context, 'drawer.about'.tr()),
            ),
            _MenuTile(
              icon: Icons.call_outlined,
              label: 'drawer.contact'.tr(),
              onTap: () => showComingSoonSnackBar(context, 'drawer.contact'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(
        DrawerHeaderBar.contentLeftPadding,
        4,
        AppSpacing.md,
        4,
      ),
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: AppTextStyles.body),
      onTap: onTap,
    );
  }
}
