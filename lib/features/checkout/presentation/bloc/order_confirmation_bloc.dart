import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../order/domain/entities/order_entity.dart';
import '../../../order/domain/usecases/watch_order_usecase.dart';
import 'order_confirmation_event.dart';
import 'order_confirmation_state.dart';

/// Only created for card orders (see `OrderConfirmationPage`) — watches the
/// order live so the page can reflect `paymentStatus` flipping from `unpaid`
/// to `paid`/`failed` once the webhook (or the reconciliation safety net)
/// processes the PaymentIntent, rather than assuming success the moment the
/// client-side payment sheet reports it.
@injectable
class OrderConfirmationBloc extends Bloc<OrderConfirmationEvent, OrderConfirmationState> {
  OrderConfirmationBloc(this._watchOrderUseCase) : super(const OrderConfirmationState()) {
    on<OrderConfirmationStarted>(_onStarted);
  }

  final WatchOrderUseCase _watchOrderUseCase;

  Future<void> _onStarted(OrderConfirmationStarted event, Emitter<OrderConfirmationState> emit) {
    return emit.forEach<OrderEntity>(
      _watchOrderUseCase(event.orderId),
      onData: (order) => OrderConfirmationState(order: order),
    );
  }
}
