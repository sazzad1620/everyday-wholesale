import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// Weight / Condition / Origin — hardcoded mock values for now; becomes
/// admin-editable once there's an admin UI.
class ProductInfoRow extends StatelessWidget {
  const ProductInfoRow({super.key, required this.weight, required this.condition, required this.origin});

  final String weight;
  final String condition;
  final String origin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _InfoBox(icon: Icons.scale_outlined, label: 'product.weight_label'.tr(), value: weight)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _InfoBox(icon: Icons.eco_outlined, label: 'product.condition_label'.tr(), value: condition),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _InfoBox(icon: Icons.public_outlined, label: 'product.origin_label'.tr(), value: origin)),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
