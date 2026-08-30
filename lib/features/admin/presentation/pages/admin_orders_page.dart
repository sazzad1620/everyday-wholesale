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
import '../../../../shared/utils/toast.dart';
import '../../../../shared/widgets/coming_soon_view.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/domain/entities/order_status.dart';
import '../../../order/presentation/widgets/order_id_header_bar.dart';
import '../../../order/presentation/widgets/order_info_row.dart';
import '../../../order/presentation/widgets/order_status_pill.dart';
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
