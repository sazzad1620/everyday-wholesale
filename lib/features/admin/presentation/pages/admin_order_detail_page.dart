import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/toast.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/domain/entities/order_status.dart';
import '../../../order/presentation/widgets/order_detail_content.dart';
import '../../../order/presentation/widgets/order_status_pill.dart';
import '../bloc/admin_order_detail_bloc.dart';
import '../bloc/admin_order_detail_event.dart';
import '../bloc/admin_order_detail_state.dart';

/// Admin's order detail — same content as the customer's [OrderDetailPage],
/// plus a tappable status pill. Reached from [AdminOrdersPage]; the full
/// [OrderEntity] is carried via `extra` (already fetched by the list), same
/// as the customer side. Pops with `true` if the status actually changed, so
/// the list behind it knows to refresh — same "push, refresh if true"
/// pattern as the category/product forms.
class AdminOrderDetailPage extends StatelessWidget {
  const AdminOrderDetailPage({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<AdminOrderDetailBloc>(), child: _AdminOrderDetailView(order: order));
  }
}

class _AdminOrderDetailView extends StatefulWidget {
  const _AdminOrderDetailView({required this.order});

  final OrderEntity order;

  @override
  State<_AdminOrderDetailView> createState() => _AdminOrderDetailViewState();
}

class _AdminOrderDetailViewState extends State<_AdminOrderDetailView> {
  late OrderStatus _status = widget.order.status;
  OrderStatus? _previousStatus;
  bool _changed = false;

  void _onStatusSelected(OrderStatus status) {
    if (status == _status) return;
    _previousStatus = _status;
    setState(() => _status = status);
    context.read<AdminOrderDetailBloc>().add(
      AdminOrderDetailStatusChangeRequested(orderId: widget.order.id, status: status),
    );
  }

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
              onMenuTap: () => context.pop(_changed),
              onAccountTap: () => openAccountMenu(context),
            ),
            Expanded(
              child: BlocListener<AdminOrderDetailBloc, AdminOrderDetailState>(
                listenWhen: (previous, current) => previous.isUpdating && !current.isUpdating,
                listener: (context, state) {
                  if (state.errorMessage != null) {
                    AppToast.show(context, state.errorMessage!, type: ToastType.error);
                    if (_previousStatus != null) setState(() => _status = _previousStatus!);
                  } else if (state.success) {
                    _changed = true;
                  }
                },
                child: OrderDetailContent(
                  order: widget.order,
                  statusWidget: OrderStatusPill(status: _status, onChanged: _onStatusSelected),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
