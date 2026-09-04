import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/di/injection_container.dart';
import '../../../../../config/routes/route_paths.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_spacing.dart';
import '../../../../../shared/theme/app_text_styles.dart';
import '../../../../../shared/utils/toast.dart';
import '../../../../../shared/widgets/coming_soon_view.dart';
import '../../../../order/domain/entities/order_entity.dart';
import '../../../../order/domain/entities/order_status.dart';
import '../../../../order/domain/entities/payment_status.dart';
import '../../../../order/presentation/widgets/order_id_header_bar.dart';
import '../../../../order/presentation/widgets/order_info_row.dart';
import '../../../../order/presentation/widgets/order_status_pill.dart';
import '../../../../order/presentation/widgets/payment_status_pill.dart';
import '../../bloc/orders/admin_order_list_bloc.dart';
import '../../bloc/orders/admin_order_list_event.dart';
import '../../bloc/orders/admin_order_list_state.dart';

/// Order management — view every order, change its status. Last of the four
/// admin sections, replacing the previous "coming soon" placeholder. Same
/// list-page shape as [AdminCategoriesPage]/[AdminProductsPage], minus an
/// add action (orders are only ever created by customers at checkout).
class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminOrderListBloc>()..add(const AdminOrderListRequested()),
      child: const _AdminOrderListView(),
    );
  }
}

/// `null` filter value means "All" — kept as a plain client-side filter over
/// the already-fetched list rather than a bloc/usecase change, since
/// `GetAllOrdersUseCase` has no server-side filtering to hook into anyway.
class _AdminOrderListView extends StatefulWidget {
  const _AdminOrderListView();

  @override
  State<_AdminOrderListView> createState() => _AdminOrderListViewState();
}

class _AdminOrderListViewState extends State<_AdminOrderListView> {
  PaymentStatus? _paymentFilter;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminOrderListBloc, AdminOrderListState>(
      listenWhen: (previous, current) => previous.isUpdating && !current.isUpdating,
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppToast.show(context, state.errorMessage!, type: ToastType.error);
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('admin.nav_orders'.tr(), style: AppTextStyles.headline),
            ),
            if (state.orders.isNotEmpty) _PaymentFilterChips(selected: _paymentFilter, onSelected: _onFilterSelected),
            Expanded(child: _buildBody(context, state)),
          ],
        );
      },
    );
  }

  void _onFilterSelected(PaymentStatus? filter) => setState(() => _paymentFilter = filter);

  Widget _buildBody(BuildContext context, AdminOrderListState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.orders.isEmpty) {
      return ComingSoonView(
        icon: Icons.error_outline_rounded,
        title: 'common.generic_error'.tr(),
        message: state.errorMessage!,
      );
    }
    if (state.orders.isEmpty) {
      return ComingSoonView(
        icon: Icons.receipt_long_outlined,
        title: 'admin.orders_empty_title'.tr(),
        message: 'admin.orders_empty_message'.tr(),
      );
    }
    final filter = _paymentFilter;
    final orders = filter == null
        ? state.orders
        : state.orders.where((order) {
            // Cash on Delivery is genuinely unpaid too (no Stripe charge exists
            // until delivery), so it counts toward that filter specifically —
            // but never toward "paid"/"failed", which only ever describe a
            // real Stripe charge outcome.
            final isCod = order.stripePaymentIntentId == null;
            if (filter == PaymentStatus.unpaid) return isCod || order.paymentStatus == PaymentStatus.unpaid;
            return !isCod && order.paymentStatus == filter;
          }).toList();
    if (orders.isEmpty) {
      return ComingSoonView(
        icon: Icons.filter_alt_off_outlined,
        title: 'admin.orders_empty_title'.tr(),
        message: 'admin.payment_filter_empty_message'.tr(),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _AdminOrderCard(
          order: order,
          onStatusChanged: (status) =>
              context.read<AdminOrderListBloc>().add(AdminOrderStatusUpdateRequested(orderId: order.id, status: status)),
          onOpenDetail: () async {
            final changed = await context.push<bool>(RoutePaths.adminOrderDetail, extra: order);
            if (changed == true && context.mounted) {
              context.read<AdminOrderListBloc>().add(const AdminOrderListRequested());
            }
          },
        );
      },
    );
  }
}

/// `null` represents "All". Cash on Delivery orders (no `paymentStatus`
/// that's ever meaningful) are excluded from every filter except "All".
class _PaymentFilterChips extends StatelessWidget {
  const _PaymentFilterChips({required this.selected, required this.onSelected});

  final PaymentStatus? selected;
  final ValueChanged<PaymentStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(label: 'admin.payment_filter_all'.tr(), selected: selected == null, onTap: () => onSelected(null)),
            for (final status in PaymentStatus.values) ...[
              const SizedBox(width: AppSpacing.xs),
              _FilterChip(
                label: 'order_history.payment_status_${status.name}'.tr(),
                selected: selected == status,
                onTap: () => onSelected(status),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.25)),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.order, required this.onStatusChanged, required this.onOpenDetail});

  final OrderEntity order;
  final ValueChanged<OrderStatus> onStatusChanged;
  final VoidCallback onOpenDetail;

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
          onTap: onOpenDetail,
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
                        OrderStatusPill(status: order.status, onChanged: onStatusChanged),
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
