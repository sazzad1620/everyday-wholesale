import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/payment_status.dart';

Color _colorFor(PaymentStatus status) => switch (status) {
  PaymentStatus.unpaid => AppColors.secondary,
  PaymentStatus.paid => AppColors.primary,
  PaymentStatus.failed => AppColors.error,
};

/// Read-only color-coded chip for [PaymentStatus] — same recipe as
/// [OrderStatusPill], but deliberately has no tappable/`onChanged` variant
/// for anyone, admin included: `paymentStatus` only ever moves via the
/// Stripe webhook or the reconciliation sweep, and giving the UI a manual
/// override would undermine that guarantee.
///
/// Only meaningful for orders that actually went through Stripe — callers
/// should gate rendering this on `order.stripePaymentIntentId != null`
/// rather than showing it (permanently "unpaid") for Cash on Delivery.
class PaymentStatusPill extends StatelessWidget {
  const PaymentStatusPill({super.key, required this.status, required this.createdAt});

  final PaymentStatus status;

  /// The order's creation time — used only to soften a fresh `unpaid` order
  /// into "Processing" for [_pendingGracePeriod] rather than showing the
  /// same amber "UNPAID" a genuinely stuck order gets. Matches the exact
  /// threshold `reconcilePendingPayments` itself uses to decide something is
  /// actually stuck, so "still amber past this point" and "the backend would
  /// also consider this stuck" stay the same moment.
  final DateTime createdAt;

  static const _pendingGracePeriod = Duration(minutes: 5);

  @override
  Widget build(BuildContext context) {
    final isProcessing = status == PaymentStatus.unpaid && DateTime.now().difference(createdAt) < _pendingGracePeriod;
    final color = isProcessing ? AppColors.info : _colorFor(status);
    final label = isProcessing
        ? 'order_history.payment_status_processing'.tr()
        : 'order_history.payment_status_${status.name}'.tr();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold)),
    );
  }
}

/// Companion pill for Cash on Delivery orders — deliberately a distinct
/// neutral color from [PaymentStatusPill]'s `unpaid` (amber), even though a
/// COD order is technically "unpaid" too: card orders sitting `unpaid` past
/// a few seconds usually signal a real problem (a stuck/failed charge), while
/// COD is *expected* to sit unpaid until delivery. Keeping the colors
/// distinct stops normal COD traffic from burying real stuck-payment signals
/// at a glance, even where both get grouped under the same "Unpaid" filter.
class CodPaymentPill extends StatelessWidget {
  const CodPaymentPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'order_history.payment_status_cod'.tr(),
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
      ),
    );
  }
}
