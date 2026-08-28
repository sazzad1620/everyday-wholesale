import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/di/injection_container.dart';
import '../../../features/auth/presentation/bloc/account_bloc.dart';
import '../../../features/auth/presentation/bloc/account_event.dart';
import '../../../features/auth/presentation/bloc/account_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_input_style.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/toast.dart';
import '../buttons/primary_button.dart';
import 'auth_method_toggle.dart';
import 'dialog_shell.dart';
import 'phone_auth_steps.dart';
import 'sign_in_dialog.dart';

/// Email+password is wired to real Firebase Auth. Phone+OTP UI exists but is
/// still a preview — verifying shows a "coming soon" message rather than
/// signing up, until Phone Auth is enabled and wired for real.
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

class SignUpDialog extends StatefulWidget {
  const SignUpDialog({super.key, required this.onSwitchToSignIn});

  final VoidCallback onSwitchToSignIn;

  @override
  State<SignUpDialog> createState() => _SignUpDialogState();
}

class _SignUpDialogState extends State<SignUpDialog> {
  AuthMethod _method = AuthMethod.email;
  bool _codeSent = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
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

  void _submitEmailSignUp() {
    if (!_formKey.currentState!.validate()) return;
    getIt<AccountBloc>().add(
      AccountSignUpRequested(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _sendPhoneOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    getIt<AccountBloc>().add(AccountPhoneOtpRequested(phone, isSignUp: true));
  }

  void _verifyPhoneCode() {
    final verificationId = getIt<AccountBloc>().state.phoneVerificationId;
    if (verificationId == null) return;
    getIt<AccountBloc>().add(
      AccountPhoneOtpVerifyRequested(
        verificationId: verificationId,
        smsCode: _codeController.text.trim(),
        name: _nameController.text.trim(),
      ),
    );
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
        } else if (state.phoneVerificationId != null && !_codeSent) {
          setState(() => _codeSent = true);
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
                      child: Text('auth.sign_up_title'.tr(), style: AppTextStyles.headline.copyWith(fontSize: 20)),
                    ),
                    DialogCloseButton(onTap: () => Navigator.of(context).pop()),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('auth.sign_up_subtitle'.tr(), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.lg),
                AuthMethodToggle(selected: _method, onChanged: _selectMethod),
                const SizedBox(height: AppSpacing.lg),
                if (_method == AuthMethod.email) ...[
                  TextFormField(
                    controller: _nameController,
                    autofillHints: const [AutofillHints.name],
                    decoration: AppInputStyle.decoration(hintText: 'auth.name_hint'.tr(), radius: 14),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'auth.error_name_required'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
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
                    autofillHints: const [AutofillHints.newPassword],
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
                      if (value.length < 6) return 'auth.error_password_weak'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'auth.sign_up_action'.tr(),
                    isLoading: state.isSubmitting,
                    onTap: _submitEmailSignUp,
                  ),
                ] else if (!_codeSent) ...[
                  PhoneNumberStep(
                    leading: TextField(
                      controller: _nameController,
                      decoration: AppInputStyle.decoration(hintText: 'auth.name_hint'.tr(), radius: 14),
                    ),
                    phoneController: _phoneController,
                    actionLabel: 'auth.send_otp'.tr(),
                    isLoading: state.isSubmitting,
                    onSendCode: _sendPhoneOtp,
                  ),
                ] else ...[
                  OtpVerificationStep(
                    phone: _phoneController.text,
                    codeController: _codeController,
                    verifyLabel: 'auth.verify_sign_up'.tr(),
                    isLoading: state.isSubmitting,
                    onVerify: _verifyPhoneCode,
                    onResend: _sendPhoneOtp,
                    onChangeNumber: () => setState(() => _codeSent = false),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text('auth.have_account'.tr(), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onSwitchToSignIn,
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
          ),
        );
      },
    );
  }
}
