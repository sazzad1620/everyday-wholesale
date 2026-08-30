import 'package:flutter/material.dart';

/// Placeholder brand palette — will be replaced once UI screenshots
/// from https://gunmahalalfood.com/ are used to derive the final design.
abstract final class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color secondary = Color(0xFFFFA000);

  /// Kept equal to [surface] for now — no grey/ash page background anywhere
  /// until asked for one; separation between sections comes from hairline
  /// borders and soft shadows instead. Still a distinct token because call
  /// sites mean different things by it, so flipping this back later (or
  /// diverging it from [surface] again) won't require touching every file.
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  /// The one deliberate exception to the no-grey rule above: a flat, light
  /// ash fill for text-box-shaped controls (search bar now, real text
  /// fields later) — see [AppInputStyle]. No border on these; the fill
  /// alone is what reads as "this is a text box".
  static const Color inputFill = Color(0xFFF1F1F3);

  static const Color error = Color(0xFFD32F2F);

  /// "In progress" indicator — currently only the order-status pill's
  /// `processing` state. Distinct from [secondary] (pending/waiting) and
  /// [primary] (done/success).
  static const Color info = Color(0xFF1976D2);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFECECEC);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);
}
