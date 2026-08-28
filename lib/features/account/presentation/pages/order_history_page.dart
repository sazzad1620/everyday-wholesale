import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/coming_soon_view.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/presentation/bloc/order_history_bloc.dart';
import '../../../order/presentation/bloc/order_history_event.dart';
import '../../../order/presentation/bloc/order_history_state.dart';
import 'account_page.dart';

/// Full-screen order-history page, reached from [AccountPage]. Pushed on the
/// root navigator the same way [AccountPage] is (see `app_router.dart`), so
/// it gets the same drawer/end-drawer/bottom-nav chrome via
/// [StandaloneShellScaffold].
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
    return SafeArea(
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
                _OrderRow(label: 'order_history.order_date'.tr(), value: DateFormat.yMMMMd().format(order.createdAt)),
                const SizedBox(height: AppSpacing.xs),
                _OrderRow(label: 'order_history.order_status'.tr(), value: order.status.name.toUpperCase()),
                const SizedBox(height: AppSpacing.xs),
                _OrderRow(label: 'order_history.payment_method'.tr(), value: order.paymentMethod),
                const SizedBox(height: AppSpacing.xs),
                _OrderRow(label: 'order_history.total'.tr(), value: formatYen(order.total)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.label, required this.value});

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
