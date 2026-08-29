import 'package:equatable/equatable.dart';

import '../../../order/domain/entities/order_status.dart';

abstract class AdminOrderListEvent extends Equatable {
  const AdminOrderListEvent();

  @override
  List<Object?> get props => [];
}

class AdminOrderListRequested extends AdminOrderListEvent {
  const AdminOrderListRequested();
}

class AdminOrderStatusUpdateRequested extends AdminOrderListEvent {
  const AdminOrderStatusUpdateRequested({required this.orderId, required this.status});

  final String orderId;
  final OrderStatus status;

  @override
  List<Object?> get props => [orderId, status];
}
