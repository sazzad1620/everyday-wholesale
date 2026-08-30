import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/order_status.dart';

Color _colorFor(OrderStatus status) => switch (status) {
  OrderStatus.pending => AppColors.secondary,
  OrderStatus.processing => AppColors.info,
  OrderStatus.completed => AppColors.primary,
  OrderStatus.cancelled => AppColors.error,
};

/// A color-coded status chip, shared by the customer and admin order
/// cards/detail views. Pass [onChanged] to make it a tappable popup menu
/// (admin only); leave it `null` for a plain read-only chip (customer).
class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill({super.key, required this.status, this.onChanged});

  final OrderStatus status;
  final ValueChanged<OrderStatus>? onChanged;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status.name.toUpperCase(), style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold)),
          if (onChanged != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 16),
          ],
        ],
      ),
    );

    final handler = onChanged;
    if (handler == null) return chip;

    return PopupMenuButton<OrderStatus>(
      initialValue: status,
      onSelected: handler,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surface,
      itemBuilder: (context) => [
        for (final value in OrderStatus.values)
          PopupMenuItem<OrderStatus>(
            value: value,
            child: Text(
              value.name.toUpperCase(),
              style: AppTextStyles.body.copyWith(
                color: value == status ? AppColors.primary : AppColors.textPrimary,
                fontWeight: value == status ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
      ],
      child: chip,
    );
  }
}
