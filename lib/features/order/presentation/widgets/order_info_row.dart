import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// A label-left / bold-value-right row — shared by every order card/detail
/// view that lists plain fields (date, payment method, total, ...).
class OrderInfoRow extends StatelessWidget {
  const OrderInfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return OrderLabeledRow(
      label: label,
      trailing: Text(
        value,
        textAlign: TextAlign.end,
        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// A label on the left and any widget (a value, a status pill) on the right.
/// The right side keeps its natural width up to 60% of the row (wrapping
/// beyond that) and the label takes the rest, wrapping too — a plain
/// `spaceBetween` row overflowed with long labels (Japanese, large text
/// sizes, narrow phones).
class OrderLabeledRow extends StatelessWidget {
  const OrderLabeledRow({super.key, required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: AppSpacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.6),
            child: trailing,
          ),
        ],
      ),
    );
  }
}
