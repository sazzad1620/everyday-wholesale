import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.isLoading = false,
  });

  final Widget? leading;
  final TextEditingController phoneController;
  final String actionLabel;
  final VoidCallback onSendCode;

  /// True while the OTP send request is in flight.
  final bool isLoading;

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
        PrimaryButton(label: actionLabel, isLoading: isLoading, onTap: onSendCode),
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
    required this.onResend,
    this.isLoading = false,
  });

  final String phone;
  final TextEditingController codeController;
  final String verifyLabel;
  final VoidCallback onVerify;
  final VoidCallback onChangeNumber;

  /// Re-sends the OTP to the same number — actual resend, not just the
  /// local cooldown reset (that still happens too, in [_startCountdown]).
  final VoidCallback onResend;

  /// True while a verify (or resend) request is in flight.
  final bool isLoading;

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
        _OtpCodeBoxes(controller: widget.codeController),
        const SizedBox(height: AppSpacing.sm),
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
              onTap: canResend
                  ? () {
                      widget.onResend();
                      _startCountdown();
                    }
                  : null,
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
        PrimaryButton(label: widget.verifyLabel, isLoading: widget.isLoading, onTap: widget.onVerify),
      ],
    );
  }
}

/// Six individual single-digit boxes instead of one text field — keeps
/// [controller] (read by the dialogs for verification) in sync as the
/// combined string on every keystroke. Deliberately minimal: no placeholder
/// digits, no per-box borders beyond the fill, just a focus highlight.
class _OtpCodeBoxes extends StatefulWidget {
  const _OtpCodeBoxes({required this.controller});

  final TextEditingController controller;

  static const _length = 6;

  @override
  State<_OtpCodeBoxes> createState() => _OtpCodeBoxesState();
}

class _OtpCodeBoxesState extends State<_OtpCodeBoxes> {
  late final _digitControllers = List.generate(_OtpCodeBoxes._length, (_) => TextEditingController());
  late final _focusNodes = List.generate(_OtpCodeBoxes._length, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _digitControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _OtpCodeBoxes._length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    widget.controller.text = _digitControllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_OtpCodeBoxes._length, (index) {
        return SizedBox(
          width: 44,
          height: 52,
          child: TextField(
            controller: _digitControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: AppTextStyles.headline.copyWith(fontSize: 20),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.inputFill,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            onChanged: (value) => _onDigitChanged(index, value),
          ),
        );
      }),
    );
  }
}
