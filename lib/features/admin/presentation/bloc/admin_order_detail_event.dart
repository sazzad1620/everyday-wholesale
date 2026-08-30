import 'package:equatable/equatable.dart';

import '../../../order/domain/entities/order_status.dart';

abstract class AdminOrderDetailEvent extends Equatable {
  const AdminOrderDetailEvent();

  @override
  List<Object?> get props => [];
}

class AdminOrderDetailStatusChangeRequested extends AdminOrderDetailEvent {
  const AdminOrderDetailStatusChangeRequested({required this.orderId, required this.status});

  final String orderId;
  final OrderStatus status;

  @override
  List<Object?> get props => [orderId, status];
}
