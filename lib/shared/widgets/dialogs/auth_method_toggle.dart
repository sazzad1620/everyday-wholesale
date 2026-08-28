import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Which credential the sign-in/sign-up dialog is currently collecting.
enum AuthMethod { email, phone }

/// Pill-style segmented control switching [SignInDialog]/[SignUpDialog]
/// between email+password and phone+OTP.
class AuthMethodToggle extends StatelessWidget {
  const AuthMethodToggle({super.key, required this.selected, required this.onChanged});

  final AuthMethod selected;
  final ValueChanged<AuthMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: _MethodSegment(
              label: 'auth.email_tab'.tr(),
              icon: Icons.email_outlined,
              selected: selected == AuthMethod.email,
              onTap: () => onChanged(AuthMethod.email),
            ),
          ),
          Expanded(
            child: _MethodSegment(
              label: 'auth.phone_tab'.tr(),
              icon: Icons.phone_outlined,
              selected: selected == AuthMethod.phone,
              onTap: () => onChanged(AuthMethod.phone),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodSegment extends StatelessWidget {
  const _MethodSegment({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
