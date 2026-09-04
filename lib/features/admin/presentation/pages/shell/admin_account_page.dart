import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/di/injection_container.dart';
import '../../../../../config/routes/route_paths.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_spacing.dart';
import '../../../../../shared/theme/app_text_styles.dart';
import '../../../../../shared/widgets/navigation/app_header.dart';
import '../../../../account/presentation/pages/account_page.dart';
import '../../../../auth/presentation/bloc/account_bloc.dart';
import '../../../../auth/presentation/bloc/account_event.dart';
import '../../../../auth/presentation/bloc/account_state.dart';

/// Admin's own profile — reached from the admin shell's header account icon
/// (see [openAccountMenu]'s admin branch). Deliberately **not** the
/// customer-facing `AccountPage`: no `StandaloneShellScaffold` (a plain
/// [Scaffold] instead), since an admin should never be handed the
/// Home/Wishlist/Cart bottom nav — tapping any of those would drop them into
/// the customer storefront, which isn't a state an admin should be able to
/// reach. Also drops the Address/Order History/My Reviews rows, none of
/// which apply to an admin account.
class AdminAccountPage extends StatelessWidget {
  const AdminAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              showSearchBar: false,
              showBackButton: true,
              onMenuTap: () => context.pop(),
              onAccountTap: () => openAccountMenu(context),
            ),
            Expanded(
              child: BlocBuilder<AccountBloc, AccountState>(
                bloc: getIt<AccountBloc>(),
                builder: (context, state) {
                  final user = state.user;
                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user?.name ?? '', style: AppTextStyles.title),
                                Text(
                                  user?.email ?? '',
                                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                        title: Text(
                          'account.edit_profile'.tr(),
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                        ),
                        onTap: () => context.push(RoutePaths.editProfile),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                        title: Text(
                          'account.logout'.tr(),
                          style: AppTextStyles.body.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                        ),
                        onTap: () {
                          getIt<AccountBloc>().add(const AccountSignOutRequested());
                          context.go(RoutePaths.home);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
