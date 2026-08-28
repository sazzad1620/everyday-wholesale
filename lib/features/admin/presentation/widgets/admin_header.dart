import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/account_bloc.dart';
import '../../../auth/presentation/bloc/account_event.dart';

/// Deliberately its own header, not the customer [AppHeader] — a search bar
/// and customer greeting don't belong in a back-office context. Just brand
/// + the signed-in admin's name + a logout action.
class AdminHeader extends StatelessWidget implements PreferredSizeWidget {
  const AdminHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = getIt<AccountBloc>().state.user;
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.15))),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Image.asset(AssetPaths.logo, height: 28),
            const SizedBox(width: AppSpacing.xs),
            Text('admin.panel_title'.tr(), style: AppTextStyles.title),
            const Spacer(),
            if (user != null)
              Text(user.name, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            IconButton(
              tooltip: 'admin.logout'.tr(),
              icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
              onPressed: () {
                getIt<AccountBloc>().add(const AccountSignOutRequested());
                context.go(RoutePaths.home);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
