import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/constants/pricing_constants.dart';
import '../../core/utils/cart_totals.dart';
import '../../core/utils/currency_formatter.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum _RowStyle { normal, subtotal, total }

/// The Product Total / Discount / Tax / Shipping / Sub Total / Voucher /
/// Total rows — shared by the cart page and the checkout page's order
/// summary so both always render the breakdown identically.
class CartTotalsBreakdown extends StatelessWidget {
  const CartTotalsBreakdown({super.key, required this.totals});

  final CartTotals totals;

  @override
  Widget build(BuildContext context) {
    final taxRatePercent = (PricingConstants.taxRate * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryRow(label: 'cart.product_total'.tr(), value: formatYen(totals.productTotal)),
        const SizedBox(height: AppSpacing.xs),
        _SummaryRow(label: 'cart.discount'.tr(), value: '(-) ${formatYen(totals.discount)}'),
        const SizedBox(height: AppSpacing.xs),
        _SummaryRow(label: 'cart.tax_label'.tr(namedArgs: {'rate': '$taxRatePercent'}), value: formatYen(totals.tax)),
        const SizedBox(height: AppSpacing.xs),
        _SummaryRow(
          label: 'cart.shipping_charge'.tr(),
          value: totals.shippingFee == 0 ? 'cart.shipping_free'.tr() : formatYen(totals.shippingFee),
          valueColor: totals.shippingFee == 0 ? AppColors.primary : null,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Divider(height: 1, color: AppColors.inputFill),
        ),
        _SummaryRow(label: 'cart.sub_total'.tr(), value: formatYen(totals.subTotal), style: _RowStyle.subtotal),
        const SizedBox(height: AppSpacing.xs),
        _SummaryRow(label: 'cart.voucher_label'.tr(), value: '(-) ${formatYen(totals.voucherDeduction)}'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Divider(height: 1, color: AppColors.inputFill),
        ),
        _SummaryRow(label: 'cart.total'.tr(), value: formatYen(totals.total), style: _RowStyle.total),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.style = _RowStyle.normal, this.valueColor});

  final String label;
  final String value;
  final _RowStyle style;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    late final TextStyle labelStyle;
    late final TextStyle valueStyle;
    switch (style) {
      case _RowStyle.normal:
        labelStyle = AppTextStyles.body.copyWith(color: AppColors.textSecondary);
        valueStyle = AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: valueColor);
      case _RowStyle.subtotal:
        labelStyle = AppTextStyles.body.copyWith(fontWeight: FontWeight.w700);
        valueStyle = AppTextStyles.body.copyWith(fontWeight: FontWeight.w700);
      case _RowStyle.total:
        labelStyle = AppTextStyles.title.copyWith(fontSize: 16);
        valueStyle = AppTextStyles.title.copyWith(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.bold);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }
}
