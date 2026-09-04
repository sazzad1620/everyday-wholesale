import 'package:equatable/equatable.dart';

import '../../../../order/domain/entities/order_entity.dart';

/// Single-class, flag-based state (matching [CategoryListState]) — updating
/// an order's status must keep the current list on screen (only
/// [isUpdating] toggles) instead of swapping to a bare loading state.
class AdminOrderListState extends Equatable {
  const AdminOrderListState({
    this.isLoading = false,
    this.orders = const [],
    this.errorMessage,
    this.isUpdating = false,
  });

  final bool isLoading;
  final List<OrderEntity> orders;
  final String? errorMessage;
  final bool isUpdating;

  @override
  List<Object?> get props => [isLoading, orders, errorMessage, isUpdating];
}
