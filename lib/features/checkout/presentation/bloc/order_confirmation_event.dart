import 'package:equatable/equatable.dart';

abstract class OrderConfirmationEvent extends Equatable {
  const OrderConfirmationEvent();

  @override
  List<Object?> get props => [];
}

/// Starts watching the order live — only dispatched for card orders, where
/// [OrderConfirmationBloc.close] is used, later, to stop watching once the
/// page unmounts. Cash orders never need this: they're already final by the
/// time the customer sees this page.
class OrderConfirmationStarted extends OrderConfirmationEvent {
  const OrderConfirmationStarted(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}
