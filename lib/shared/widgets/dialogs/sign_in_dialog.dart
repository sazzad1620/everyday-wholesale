import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/di/injection_container.dart';
import '../../../config/routes/route_paths.dart';
import '../../../features/auth/presentation/bloc/account_bloc.dart';
import '../../../features/auth/presentation/bloc/account_event.dart';
import '../../../features/auth/presentation/bloc/account_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_input_style.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/toast.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';
import 'auth_method_toggle.dart';
import 'dialog_shell.dart';
import 'phone_auth_steps.dart';
import 'sign_up_dialog.dart';

/// Entry point for the header's account icon when signed out — see
/// `openAccountMenu` in `account_page.dart`.
///
/// Email+password is wired to real Firebase Auth. Phone+OTP UI exists but is
/// still a preview — verifying shows a "coming soon" message rather than
/// signing in, until Phone Auth is enabled and wired for real.
Future<void> showSignInDialog(BuildContext context) {
  return showBlurredDialog(
    context: context,
    builder: (dialogContext) => SignInDialog(
      onSwitchToSignUp: () {
        Navigator.of(dialogContext).pop();
        showSignUpDialog(context);
      },
    ),
  );
}

class SignInDialog extends StatefulWidget {
  const SignInDialog({super.key, required this.onSwitchToSignUp});

  final VoidCallback onSwitchToSignUp;

  @override
  State<SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<SignInDialog> {
  AuthMethod _method = AuthMethod.email;
  bool _codeSent = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _selectMethod(AuthMethod method) => setState(() {
    _method = method;
    _codeSent = false;
  });

  void _submitEmailSignIn() {
    if (!_formKey.currentState!.validate()) return;
    getIt<AccountBloc>().add(
      AccountSignInRequested(email: _emailController.text.trim(), password: _passwordController.text),
    );
  }

  void _sendPhoneOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    getIt<AccountBloc>().add(AccountPhoneOtpRequested(phone, isSignUp: false));
  }

  void _verifyPhoneCode() {
    final verificationId = getIt<AccountBloc>().state.phoneVerificationId;
    if (verificationId == null) return;
    getIt<AccountBloc>().add(
      AccountPhoneOtpVerifyRequested(verificationId: verificationId, smsCode: _codeController.text.trim()),
    );
  }

  void _forgotPassword() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppToast.show(context, 'auth.error_email_invalid'.tr(), type: ToastType.error);
      return;
    }
    getIt<AccountBloc>().add(AccountPasswordResetRequested(email));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountBloc, AccountState>(
      bloc: getIt<AccountBloc>(),
      listenWhen: (previous, current) => previous.isSubmitting && !current.isSubmitting,
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppToast.show(context, state.errorMessage!, type: ToastType.error);
        } else if (state.isLoggedIn) {
          Navigator.of(context).pop();
          // Temporary proof-of-concept redirect — see AdminDashboardPage's
          // doc comment. Will move to a proper post-login redirect once the
          // real admin dashboard (roadmap Phase 5) exists.
          if (state.user!.isAdmin) {
            context.push(RoutePaths.admin);
          }
        } else if (state.phoneVerificationId != null && !_codeSent) {
          setState(() => _codeSent = true);
        } else if (state.passwordResetEmailSent) {
          AppToast.show(context, 'auth.password_reset_sent'.tr(), type: ToastType.success);
        }
      },
      builder: (context, state) {
        return DialogCard(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text('auth.sign_in_title'.tr(), style: AppTextStyles.headline.copyWith(fontSize: 20)),
                    ),
                    DialogCloseButton(onTap: () => Navigator.of(context).pop()),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('auth.sign_in_subtitle'.tr(), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.lg),
                AuthMethodToggle(selected: _method, onChanged: _selectMethod),
                const SizedBox(height: AppSpacing.lg),
                if (_method == AuthMethod.email) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: AppInputStyle.decoration(hintText: 'auth.email_hint'.tr(), radius: 14),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'auth.error_email_required'.tr();
                      if (!value.contains('@')) return 'auth.error_email_invalid'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    decoration: AppInputStyle.decoration(
                      hintText: 'auth.password_hint'.tr(),
                      radius: 14,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'auth.error_password_required'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _forgotPassword,
                      child: Text(
                        'auth.forgot_password'.tr(),
                        style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(
                    label: 'auth.sign_in_action'.tr(),
                    isLoading: state.isSubmitting,
                    onTap: _submitEmailSignIn,
                  ),
                ] else if (!_codeSent) ...[
                  PhoneNumberStep(
                    phoneController: _phoneController,
                    actionLabel: 'auth.send_otp'.tr(),
                    isLoading: state.isSubmitting,
                    onSendCode: _sendPhoneOtp,
                  ),
                ] else ...[
                  OtpVerificationStep(
                    phone: _phoneController.text,
                    codeController: _codeController,
                    verifyLabel: 'auth.verify_sign_in'.tr(),
                    isLoading: state.isSubmitting,
                    onVerify: _verifyPhoneCode,
                    onResend: _sendPhoneOtp,
                    onChangeNumber: () => setState(() => _codeSent = false),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.2))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text(
                        'auth.or_divider'.tr(),
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.2))),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SecondaryButton(
                  label: 'auth.continue_with_google'.tr(),
                  isLoading: state.isSubmitting,
                  onTap: () => getIt<AccountBloc>().add(const AccountGoogleSignInRequested()),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text('auth.no_account'.tr(), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onSwitchToSignUp,
                        child: Text(
                          'auth.sign_up_action'.tr(),
                          style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
