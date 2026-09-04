import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/cart_totals.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/toast.dart';
import '../../../../shared/widgets/cart_totals_breakdown.dart';
import '../../domain/entities/order_entity.dart';
import 'order_address_card.dart';
import 'order_id_header_bar.dart';
import 'order_info_row.dart';
import 'order_item_tile.dart';

/// The full body of the order-detail page — product breakdown, delivery
/// address, and cost breakdown — shared by the customer and admin detail
/// pages. [statusWidget] is the only piece that differs between them (a
/// plain read-only chip for the customer, a tappable one for admin), so it's
/// injected rather than built in here. [paymentStatusPill] is optional and
/// only ever passed for card orders (never Cash on Delivery); leave it
/// `null` to omit the row entirely. [showPaymentIntentId] shows a
/// tap-to-copy Stripe reference row — only ever passed `true` by the admin
/// detail page (a support/lookup aid; means nothing to a customer).
class OrderDetailContent extends StatelessWidget {
  const OrderDetailContent({
    super.key,
    required this.order,
    required this.statusWidget,
    this.paymentStatusPill,
    this.showPaymentIntentId = false,
  });

  final OrderEntity order;
  final Widget statusWidget;
  final Widget? paymentStatusPill;
  final bool showPaymentIntentId;

  @override
  Widget build(BuildContext context) {
    final totals = CartTotals(
      productTotal: order.itemTotal,
      discount: order.discount,
      tax: order.tax,
      shippingFee: order.shippingFee,
      subTotal: order.subTotal,
      voucherDeduction: order.voucherDeduction,
      total: order.total,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _Card(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OrderIdHeaderBar(orderId: order.id),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    OrderInfoRow(label: 'order_history.order_date'.tr(), value: DateFormat.yMMMMd().format(order.createdAt)),
                    const SizedBox(height: AppSpacing.xs),
                    OrderInfoRow(label: 'order_history.payment_method'.tr(), value: order.paymentMethod),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'order_history.order_status'.tr(),
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        ),
                        statusWidget,
                      ],
                    ),
                    if (paymentStatusPill != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'order_history.payment_status'.tr(),
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                          paymentStatusPill!,
                        ],
                      ),
                    ],
                    if (showPaymentIntentId && order.stripePaymentIntentId != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _CopyableInfoRow(
                        label: 'admin.payment_reference_label'.tr(),
                        value: order.stripePaymentIntentId!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OrderAddressCard(
          addressLine: order.addressLine,
          phone: order.addressPhone,
          receiverName: order.addressReceiverName,
        ),
        const SizedBox(height: AppSpacing.md),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('order_history.items_title'.tr(), style: AppTextStyles.title),
              for (final item in order.items) ...[
                const Divider(height: AppSpacing.md, color: AppColors.inputFill),
                OrderItemTile(item: item),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Card(child: CartTotalsBreakdown(totals: totals)),
      ],
    );
  }
}

/// Same label/value look as [OrderInfoRow], but tapping the value copies it
/// to the clipboard — for a field whose only real purpose is being pasted
/// into Stripe's dashboard search bar.
class _CopyableInfoRow extends StatelessWidget {
  const _CopyableInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) AppToast.show(context, 'common.copied_to_clipboard'.tr(), type: ToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        const SizedBox(width: AppSpacing.sm),
        // Expanded here (rather than the spaceBetween the rest of this
        // file's rows use) is what actually gives the value `Text` below a
        // bounded width to ellipsize against — without it, an unconstrained
        // Row sizes to its content's full intrinsic width regardless of
        // `Flexible`/`overflow`, which is exactly what let a long
        // PaymentIntent id overflow the screen on narrow devices.
        Expanded(
          child: InkWell(
            onTap: () => _copy(context),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.copy_rounded, size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(AppSpacing.md)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
