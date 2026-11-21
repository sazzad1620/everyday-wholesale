import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Shared "text box" look — flat [AppColors.inputFill], fully rounded, no
/// border. Used by the search bar now; reuse this for every real text
/// field added later (checkout address, etc.) so they all match.
abstract final class AppInputStyle {
  static const double radius = 28;

  /// `TextField`/`TextFormField`'s own `scrollPadding` — how much clearance
  /// a field asks for from its scrollable's edges when the keyboard opens
  /// and auto-scrolls it into view. Flutter's default (`EdgeInsets.all(20)`)
  /// leaves barely any room above the field, so it lands pinned right at the
  /// top edge — cropping its own label or whatever was above it.
  ///
  /// Kept modest on purpose: this same padding is what `EditableText` also
  /// uses to keep the caret on screen on every keystroke, not just the
  /// initial focus scroll. Asking for too much here (100+) can make that
  /// per-keystroke re-scroll request more room than the viewport actually
  /// has left once the keyboard is up, which is what caused the visible
  /// overshoot-then-settle glitch (a scroll past the real content, then a
  /// correction back down) — so this stays small: just enough to clear the
  /// field's own label, not a whole section above it.
  static const EdgeInsets fieldScrollPadding = EdgeInsets.fromLTRB(20, 48, 20, 20);

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
