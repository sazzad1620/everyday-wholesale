import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/cart_totals.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
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
/// injected rather than built in here.
class OrderDetailContent extends StatelessWidget {
  const OrderDetailContent({super.key, required this.order, required this.statusWidget});

  final OrderEntity order;
  final Widget statusWidget;

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
