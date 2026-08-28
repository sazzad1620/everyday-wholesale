import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';
import 'dialog_shell.dart';

/// "Are you sure?" prompt — built for admin delete actions (no such pattern
/// existed anywhere in the app before), but generic enough for any
/// confirm/cancel decision. Returns `true` only if the destructive/confirm
/// action was tapped; `false`/`null` (dismissed) otherwise.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool isDestructive = true,
}) async {
  final result = await showBlurredDialog<bool>(
    context: context,
    builder: (dialogContext) => DialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: confirmLabel,
            onTap: () => Navigator.of(dialogContext).pop(true),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: cancelLabel ?? 'Cancel',
            onTap: () => Navigator.of(dialogContext).pop(false),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
