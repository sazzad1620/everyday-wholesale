import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/toast.dart';
import '../../../../shared/widgets/coming_soon_view.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/domain/entities/order_status.dart';
import '../bloc/admin_order_list_bloc.dart';
import '../bloc/admin_order_list_event.dart';
import '../bloc/admin_order_list_state.dart';

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

class _AdminOrderListView extends StatelessWidget {
  const _AdminOrderListView();

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
            Expanded(child: _buildBody(context, state)),
          ],
        );
      },
    );
  }

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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      itemCount: state.orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final order = state.orders[index];
        return _AdminOrderCard(
          order: order,
          onStatusChanged: (status) =>
              context.read<AdminOrderListBloc>().add(AdminOrderStatusUpdateRequested(orderId: order.id, status: status)),
        );
      },
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.order, required this.onStatusChanged});

  final OrderEntity order;
  final ValueChanged<OrderStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    // Same header-bar-plus-rows recipe as the customer-side `_OrderCard` in
    // order_history_page.dart, with a status pill (tap to change) swapped in
    // for the plain status text row.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            color: AppColors.primary,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${'order_history.order_id'.tr()}  ', style: AppTextStyles.body.copyWith(color: Colors.white)),
                  TextSpan(
                    text: order.id,
                    style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _InfoRow(label: 'order_history.order_date'.tr(), value: DateFormat.yMMMMd().format(order.createdAt)),
                const SizedBox(height: AppSpacing.xs),
                _InfoRow(label: 'admin.order_customer'.tr(), value: order.addressPhone),
                const SizedBox(height: AppSpacing.xs),
                _InfoRow(label: 'order_history.payment_method'.tr(), value: order.paymentMethod),
                const SizedBox(height: AppSpacing.xs),
                _InfoRow(label: 'order_history.total'.tr(), value: formatYen(order.total)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'order_history.order_status'.tr(),
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                    _StatusPill(status: order.status, onChanged: onStatusChanged),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.onChanged});

  final OrderStatus status;
  final ValueChanged<OrderStatus> onChanged;

  Color get _color => switch (status) {
    OrderStatus.pending => AppColors.secondary,
    OrderStatus.completed => AppColors.primary,
    OrderStatus.cancelled => AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<OrderStatus>(
      initialValue: status,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surface,
      itemBuilder: (context) => [
        for (final value in OrderStatus.values)
          PopupMenuItem<OrderStatus>(
            value: value,
            child: Text(
              value.name.toUpperCase(),
              style: AppTextStyles.body.copyWith(
                color: value == status ? AppColors.primary : AppColors.textPrimary,
                fontWeight: value == status ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status.name.toUpperCase(),
              style: AppTextStyles.caption.copyWith(color: _color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, color: _color, size: 16),
          ],
        ),
      ),
    );
  }
}
