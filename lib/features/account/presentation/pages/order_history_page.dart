import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/coming_soon_view.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../checkout/presentation/pages/order_confirmation_page.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/domain/entities/payment_status.dart';
import '../../../order/presentation/bloc/order_history_bloc.dart';
import '../../../order/presentation/bloc/order_history_event.dart';
import '../../../order/presentation/bloc/order_history_state.dart';
import '../../../order/presentation/widgets/order_id_header_bar.dart';
import '../../../order/presentation/widgets/order_info_row.dart';
import '../../../order/presentation/widgets/order_status_pill.dart';
import '../../../order/presentation/widgets/payment_status_pill.dart';
import '../../../payment/presentation/widgets/retry_payment_button.dart';
import 'account_page.dart';

/// Full-screen order-history page, reached from [AccountPage]. Pushed on the
/// root navigator the same way [AccountPage] is (see `app_router.dart`), but
/// — unlike [AccountPage] — a plain [Scaffold] with a back arrow, same as
/// `EditProfilePage`/`AddressFormPage`: a page you drill into rather than
/// switch to doesn't need the drawer/bottom-nav chrome.
class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrderHistoryBloc>()..add(const OrderHistoryRequested()),
      child: const _OrderHistoryView(),
    );
  }
}

class _OrderHistoryView extends StatelessWidget {
  const _OrderHistoryView();

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
              child: BlocBuilder<OrderHistoryBloc, OrderHistoryState>(
                builder: (context, state) {
                  return switch (state) {
                    OrderHistoryInitial() || OrderHistoryInProgress() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    OrderHistoryFailure(:final message) => ComingSoonView(
                      icon: Icons.error_outline_rounded,
                      title: 'common.generic_error'.tr(),
                      message: message,
                    ),
                    OrderHistoryLoaded(:final orders) when orders.isEmpty => ComingSoonView(
                      icon: Icons.receipt_long_outlined,
                      title: 'order_history.empty_title'.tr(),
                      message: 'order_history.empty_message'.tr(),
                    ),
                    OrderHistoryLoaded(:final orders) => ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) => _OrderCard(order: orders[index]),
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(RoutePaths.orderDetail, extra: order),
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
                    const SizedBox(height: AppSpacing.xs),
                    OrderInfoRow(label: 'order_history.total'.tr(), value: formatYen(order.total)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'order_history.order_status'.tr(),
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        ),
                        OrderStatusPill(status: order.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'order_history.payment_status'.tr(),
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        ),
                        order.stripePaymentIntentId != null
                            ? PaymentStatusPill(status: order.paymentStatus, createdAt: order.createdAt)
                            : const CodPaymentPill(),
                      ],
                    ),
                    if (order.stripePaymentIntentId != null && order.paymentStatus == PaymentStatus.failed) ...[
                      const SizedBox(height: AppSpacing.sm),
                      RetryPaymentButton(
                        orderId: order.id,
                        onSucceeded: () async {
                          await context.push(
                            RoutePaths.orderConfirmation,
                            extra: OrderConfirmationArgs(order: order, isCardOrder: true),
                          );
                          if (context.mounted) {
                            context.read<OrderHistoryBloc>().add(const OrderHistoryRequested());
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
