import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_input_style.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/primary_button.dart';

/// First half of the phone+OTP flow — collect the number (plus, for sign-up,
/// whatever [leading] fields it's paired with) and request a code. Shared by
/// [SignInDialog] and [SignUpDialog] since it's identical either way.
class PhoneNumberStep extends StatelessWidget {
  const PhoneNumberStep({
    super.key,
    this.leading,
    required this.phoneController,
    required this.actionLabel,
    required this.onSendCode,
  });

  final Widget? leading;
  final TextEditingController phoneController;
  final String actionLabel;
  final VoidCallback onSendCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (leading != null) ...[leading!, const SizedBox(height: AppSpacing.sm)],
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: AppInputStyle.decoration(
            hintText: 'auth.phone_hint'.tr(),
            prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
            radius: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: actionLabel, onTap: onSendCode),
      ],
    );
  }
}

/// Second half — enter the code just sent to [phone]. Shared the same way
/// as [PhoneNumberStep]; owns its own resend-cooldown timer since that's
/// purely local presentation, not something either dialog needs to track.
class OtpVerificationStep extends StatefulWidget {
  const OtpVerificationStep({
    super.key,
    required this.phone,
    required this.codeController,
    required this.verifyLabel,
    required this.onVerify,
    required this.onChangeNumber,
  });

  final String phone;
  final TextEditingController codeController;
  final String verifyLabel;
  final VoidCallback onVerify;
  final VoidCallback onChangeNumber;

  @override
  State<OtpVerificationStep> createState() => _OtpVerificationStepState();
}

class _OtpVerificationStepState extends State<OtpVerificationStep> {
  // 60s for now — revisit once real Phone Auth is wired and we have a feel
  // for actual delivery latency.
  static const _resendCooldown = 60;

  int _secondsRemaining = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsRemaining == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'auth.otp_sent_message'.tr(namedArgs: {'phone': widget.phone}),
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: widget.codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 8),
          decoration: AppInputStyle.decoration(hintText: 'auth.otp_hint'.tr(), radius: 14).copyWith(counterText: ''),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: widget.onChangeNumber,
              child: Text(
                'auth.change_number'.tr(),
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: canResend ? _startCountdown : null,
              child: Text(
                canResend ? 'auth.resend_code'.tr() : 'auth.resend_in'.tr(namedArgs: {'seconds': '$_secondsRemaining'}),
                style: AppTextStyles.caption.copyWith(
                  color: canResend ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(label: widget.verifyLabel, onTap: widget.onVerify),
      ],
    );
  }
}
