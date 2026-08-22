import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// Free Delivery / Premium Quality / Halal Certified — same content on every
/// product, so this widget takes no product data.
class ProductHighlightBoxes extends StatelessWidget {
  const ProductHighlightBoxes({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HighlightCard(
          icon: Icons.local_shipping_outlined,
          title: 'product.free_delivery_title'.tr(),
          message: 'product.free_delivery_message'.tr(),
          axis: Axis.horizontal,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _HighlightCard(
                icon: Icons.workspace_premium_outlined,
                title: 'product.premium_quality_title'.tr(),
                message: 'product.premium_quality_message'.tr(),
                axis: Axis.vertical,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _HighlightCard(
                icon: Icons.verified_outlined,
                title: 'product.halal_certified_title'.tr(),
                message: 'product.halal_certified_message'.tr(),
                axis: Axis.vertical,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.icon, required this.title, required this.message, required this.axis});

  final IconData icon;
  final String title;
  final String message;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final iconBadge = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: AppColors.primary),
    );

    final textColumn = Column(
      crossAxisAlignment: axis == Axis.horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(
          message,
          textAlign: axis == Axis.horizontal ? TextAlign.start : TextAlign.center,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: axis == Axis.horizontal
          ? Row(
              children: [
                iconBadge,
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: textColumn),
              ],
            )
          : Column(
              children: [
                iconBadge,
                const SizedBox(height: AppSpacing.xs),
                textColumn,
              ],
            ),
    );
  }
}
