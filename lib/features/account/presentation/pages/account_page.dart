import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/dialogs/sign_in_dialog.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../../shared/widgets/navigation/desktop_body.dart';
import '../../../../shared/widgets/navigation/standalone_shell_scaffold.dart';
import '../../../auth/presentation/bloc/account_bloc.dart';
import '../../../auth/presentation/bloc/account_event.dart';
import '../../../auth/presentation/bloc/account_state.dart';

/// Single entry point for the header's account icon — routes to the
/// signed-in [AccountPage] (or, for an admin, the separate `AdminAccountPage`
/// — see its doc comment for why they can't share one) or the sign-in dialog
/// depending on [AccountBloc] state, so call sites don't need to branch
/// themselves.
void openAccountMenu(BuildContext context) {
  final user = getIt<AccountBloc>().state.user;
  if (user == null) {
    showSignInDialog(context);
  } else if (user.isAdmin) {
    context.push(RoutePaths.adminAccount);
  } else {
    context.push(RoutePaths.account);
  }
}

/// Full-screen account page, pushed outside the shell's nested navigator
/// (see `app_router.dart`'s root `navigatorKey`/`parentNavigatorKey`) since
/// "Account" isn't one of [MainShell]'s branches — it still gets the same
/// drawer/end-drawer/bottom-nav chrome via [StandaloneShellScaffold]. The
/// header's search bar is dropped since it isn't relevant here. Only ever
/// reached signed-in (see [openAccountMenu]).
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const StandaloneShellScaffold(body: _AccountView());
  }
}

class _AccountView extends StatelessWidget {
  const _AccountView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          AppHeader(
            showSearchBar: false,
            showBackButton: true,
            onMenuTap: () => context.pop(),
            onAccountTap: () => openAccountMenu(context),
          ),
          Expanded(
            child: DesktopBody(
              child: _AccountBody(
                onLogout: () {
                  getIt<AccountBloc>().add(const AccountSignOutRequested());
                  context.go(RoutePaths.home);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountBody extends StatelessWidget {
  const _AccountBody({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
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
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'account.guest_name'.tr(), style: AppTextStyles.title),
                      Text(
                        user?.email ?? 'account.guest_email'.tr(),
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            _AccountRow(
              icon: Icons.edit_outlined,
              label: 'account.edit_profile'.tr(),
              onTap: () => context.push(RoutePaths.editProfile),
            ),
            _AccountRow(
              icon: Icons.location_on_outlined,
              label: 'account.address'.tr(),
              onTap: () => context.push(RoutePaths.accountAddress),
            ),
            _AccountRow(
              icon: Icons.receipt_long_outlined,
              label: 'account.order_history'.tr(),
              onTap: () => context.push(RoutePaths.orderHistory),
            ),
            _AccountRow(
              icon: Icons.star_outline_rounded,
              label: 'account.my_reviews'.tr(),
              onTap: () => context.push(RoutePaths.myReviews),
            ),
            _AccountRow(
              icon: Icons.logout_rounded,
              label: 'account.logout'.tr(),
              onTap: onLogout,
              isDestructive: true,
            ),
          ],
        );
      },
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.icon, required this.label, this.onTap, this.isDestructive = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.textSecondary),
      title: Text(label, style: AppTextStyles.body.copyWith(color: color, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}
