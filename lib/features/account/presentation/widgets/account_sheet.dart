import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/snack_utils.dart';
import '../../../../shared/widgets/dialogs/sign_in_dialog.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';

/// Single entry point for the header's account icon — routes to the
/// signed-in account menu (bottom sheet) or the sign-in dialog depending on
/// [AccountBloc] state, so call sites don't need to branch themselves.
void openAccountMenu(BuildContext context) {
  final isLoggedIn = getIt<AccountBloc>().state.isLoggedIn;
  if (isLoggedIn) {
    showAccountSheet(context);
  } else {
    showSignInDialog(context);
  }
}

/// Only ever shown signed-in (see [openAccountMenu]) — "Logout" closes the
/// sheet and flips [AccountBloc] back to signed-out.
void showAccountSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _AccountSheet(),
  );
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: _LoggedInView(
          onLogout: () {
            Navigator.of(context).pop();
            getIt<AccountBloc>().add(const AccountLoggedOut());
          },
        ),
      ),
    );
  }
}

class _LoggedInView extends StatelessWidget {
  const _LoggedInView({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetHandle(),
        const SizedBox(height: AppSpacing.md),
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
                  Text('account.guest_name'.tr(), style: AppTextStyles.title),
                  Text(
                    'account.guest_email'.tr(),
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
          onTap: () => showComingSoonSnackBar(context, 'account.edit_profile'.tr()),
        ),
        _AccountRow(
          icon: Icons.location_on_outlined,
          label: 'account.address'.tr(),
          onTap: () => showComingSoonSnackBar(context, 'account.address'.tr()),
        ),
        _AccountRow(icon: Icons.logout_rounded, label: 'account.logout'.tr(), onTap: onLogout, isDestructive: true),
      ],
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

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
