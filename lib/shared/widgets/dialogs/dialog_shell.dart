import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Full-screen blurred backdrop + fade/scale-in transition for a small,
/// centered dialog card — the "auth dialog" look, distinct from the
/// bottom-sheet pattern ([showAccountSheet]) used for the signed-in account
/// menu. Reuse this for any future centered dialog, not just auth.
Future<T?> showBlurredDialog<T>({required BuildContext context, required WidgetBuilder builder}) {
  return showGeneralDialog<T>(
    context: context,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            // showGeneralDialog's pageBuilder skips the Material ancestor
            // showDialog would normally provide — required by TextField and
            // other Material widgets used in dialog content.
            child: Material(type: MaterialType.transparency, child: builder(context)),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

/// Same blurred backdrop as [showBlurredDialog], but sliding up from the
/// bottom instead of fading/scaling in centered — for bottom-sheet content
/// (e.g. the payment method picker) that should still match the app's one
/// "overlay" look rather than the plain dim scrim `showModalBottomSheet`
/// gives you by default.
Future<T?> showBlurredBottomSheet<T>({required BuildContext context, required WidgetBuilder builder}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Align(
          alignment: Alignment.bottomCenter,
          // showGeneralDialog's pageBuilder skips the Material ancestor
          // showModalBottomSheet would normally provide.
          child: Material(type: MaterialType.transparency, child: builder(context)),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}

/// Shared white rounded card shell for dialog content — same shadow recipe
/// as every other card in the app ([AppColors.surface], 0.14-alpha shadow),
/// just a wider corner radius since it floats over a blurred page rather
/// than sitting flat on one.
class DialogCard extends StatelessWidget {
  const DialogCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Small circular close ("X") button shared by dialog headers.
class DialogCloseButton extends StatelessWidget {
  const DialogCloseButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputFill,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.close_rounded, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
