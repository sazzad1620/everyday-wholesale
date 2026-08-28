import 'package:equatable/equatable.dart';

import '../../domain/entities/order_entity.dart';

sealed class OrderHistoryState extends Equatable {
  const OrderHistoryState();

  @override
  List<Object?> get props => [];
}

class OrderHistoryInitial extends OrderHistoryState {
  const OrderHistoryInitial();
}

class OrderHistoryInProgress extends OrderHistoryState {
  const OrderHistoryInProgress();
}

class OrderHistoryLoaded extends OrderHistoryState {
  const OrderHistoryLoaded(this.orders);

  final List<OrderEntity> orders;

  @override
  List<Object?> get props => [orders];
}

class OrderHistoryFailure extends OrderHistoryState {
  const OrderHistoryFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
