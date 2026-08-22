import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Shared "text box" look — flat [AppColors.inputFill], fully rounded, no
/// border. Used by the search bar now; reuse this for every real text
/// field added later (checkout address, etc.) so they all match.
abstract final class AppInputStyle {
  static const double radius = 28;

  /// For decorative text-box-shaped containers that aren't a real
  /// [TextField] — e.g. the search bar, which just opens something else on
  /// tap rather than accepting input directly.
  static BoxDecoration boxDecoration({double radius = AppInputStyle.radius}) => BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(radius),
      );

  /// For actual [TextField]/[TextFormField] widgets.
  static InputDecoration decoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    double radius = AppInputStyle.radius,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.inputFill,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
    );
  }
}
