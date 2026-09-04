import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/presentation/widgets/order_detail_content.dart';
import '../../../order/presentation/widgets/order_status_pill.dart';
import '../../../order/presentation/widgets/payment_status_pill.dart';
import 'account_page.dart';

/// Read-only order detail — reached by tapping a card on [OrderHistoryPage].
/// The full [OrderEntity] is already in memory there (from the history
/// fetch), so it's carried via `extra` on the route instead of being
/// re-fetched by id.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              showSearchBar: false,
              showBackButton: true,
              onMenuTap: () => context.pop(),
              onAccountTap: () => openAccountMenu(context),
            ),
            Expanded(
              child: OrderDetailContent(
                order: order,
                statusWidget: OrderStatusPill(status: order.status),
                paymentStatusPill: order.stripePaymentIntentId != null
                    ? PaymentStatusPill(
                        status: order.paymentStatus,
                        createdAt: order.createdAt,
                      )
                    : const CodPaymentPill(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
