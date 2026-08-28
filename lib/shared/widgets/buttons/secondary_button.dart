import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Outlined, flat companion to [PrimaryButton] — for a secondary action
/// sitting right next to a primary one (e.g. "Return to Shopping").
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onTap, this.isLoading = false});

  final String label;
  final VoidCallback onTap;

  /// Shows a spinner in place of the label and ignores taps.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLoading ? null : onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.textSecondary),
                  )
                : Text(
                    label,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
          ),
        ),
      ),
    );
  }
}
