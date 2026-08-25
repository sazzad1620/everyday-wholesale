import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../config/di/injection_container.dart';
import '../../../features/account/presentation/bloc/account_bloc.dart';
import '../../../features/account/presentation/bloc/account_event.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_input_style.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/primary_button.dart';
import 'dialog_shell.dart';
import 'sign_in_dialog.dart';

/// Mock-only for now — no real auth exists yet, so "Sign Up" just flips
/// [AccountBloc] to the signed-in state and closes the dialog. Wire this up
/// to Firebase Auth in the backend-integration phase.
Future<void> showSignUpDialog(BuildContext context) {
  return showBlurredDialog(
    context: context,
    builder: (dialogContext) => SignUpDialog(
      onSwitchToSignIn: () {
        Navigator.of(dialogContext).pop();
        showSignInDialog(context);
      },
    ),
  );
}

class SignUpDialog extends StatelessWidget {
  const SignUpDialog({super.key, required this.onSwitchToSignIn});

  final VoidCallback onSwitchToSignIn;

  @override
  Widget build(BuildContext context) {
    return DialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text('auth.sign_up_title'.tr(), style: AppTextStyles.headline.copyWith(fontSize: 20))),
              DialogCloseButton(onTap: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('auth.sign_up_subtitle'.tr(), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          TextField(decoration: AppInputStyle.decoration(hintText: 'auth.name_hint'.tr(), radius: 14)),
          const SizedBox(height: AppSpacing.sm),
          TextField(decoration: AppInputStyle.decoration(hintText: 'auth.email_hint'.tr(), radius: 14)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            obscureText: true,
            decoration: AppInputStyle.decoration(hintText: 'auth.password_hint'.tr(), radius: 14),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'auth.sign_up_action'.tr(),
            onTap: () {
              getIt<AccountBloc>().add(const AccountLoggedIn());
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text('auth.have_account'.tr(), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onSwitchToSignIn,
                  child: Text(
                    'auth.sign_in_action'.tr(),
                    style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
