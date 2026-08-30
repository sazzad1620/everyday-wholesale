import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// A label-left / bold-value-right row — shared by every order card/detail
/// view that lists plain fields (date, payment method, total, ...).
class OrderInfoRow extends StatelessWidget {
  const OrderInfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
