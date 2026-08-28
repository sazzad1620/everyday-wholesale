import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum ToastType { success, error, info }

/// App-wide toast — replaces [ScaffoldMessenger]/`SnackBar` everywhere
/// because a `SnackBar` is anchored to whichever `Scaffold` is below it in
/// the widget tree, which reliably renders *underneath* a blurred dialog's
/// barrier (see `showBlurredDialog`) instead of over it. This inserts
/// directly into the app's root [Overlay] instead, so it always floats above
/// everything currently on screen, dialogs included.
abstract final class AppToast {
  static OverlayEntry? _entry;

  /// Shows [message] for a few seconds, replacing any toast already showing.
  static void show(BuildContext context, String message, {ToastType type = ToastType.info}) {
    _entry?.remove();

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastOverlay(
        message: message,
        type: type,
        onFinished: () {
          if (_entry == entry) _entry = null;
          entry.remove();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

/// Convenience wrapper for the "not built yet" placeholder rows scattered
/// across the app (Edit Profile, Address, Vouchers, ...).
void showComingSoonToast(BuildContext context, String feature) {
  AppToast.show(context, 'common.coming_soon'.tr(namedArgs: {'feature': feature}));
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({required this.message, required this.type, required this.onFinished});

  final String message;
  final ToastType type;
  final VoidCallback onFinished;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> with SingleTickerProviderStateMixin {
  static const _visibleDuration = Duration(seconds: 3);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.3),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _scheduleDismiss();
  }

  Future<void> _scheduleDismiss() async {
    await Future.delayed(_visibleDuration);
    if (!mounted) return;
    await _controller.reverse();
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: bottomInset + AppSpacing.lg,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Align(
            child: Material(color: Colors.transparent, child: _ToastCard(message: widget.message, type: widget.type)),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.message, required this.type});

  final String message;
  final ToastType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      ToastType.success => (Icons.check_circle_rounded, AppColors.primary),
      ToastType.error => (Icons.error_rounded, AppColors.error),
      ToastType.info => (Icons.info_rounded, AppColors.textSecondary),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                message,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
