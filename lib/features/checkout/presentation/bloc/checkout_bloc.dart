import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/cart_totals.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/domain/usecases/place_order_usecase.dart';
import '../../../payment/domain/usecases/create_payment_intent_usecase.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';

/// One per checkout visit (`@injectable`, not shared) — reads the live cart
/// straight from the shared `CartBloc` at submit time rather than holding
/// its own copy, and clears it via `CartCleared` once the order is placed.
@injectable
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc(this._placeOrderUseCase, this._createPaymentIntentUseCase, this._cartBloc) : super(const CheckoutState()) {
    on<CheckoutOrderPlaceRequested>(_onOrderPlaceRequested);
    on<CheckoutPaymentConfirmed>(_onPaymentConfirmed);
    on<CheckoutPaymentFailed>(_onPaymentFailed);
    on<CheckoutPaymentCanceled>(_onPaymentCanceled);
  }

  final PlaceOrderUseCase _placeOrderUseCase;
  final CreatePaymentIntentUseCase _createPaymentIntentUseCase;
  final CartBloc _cartBloc;

  /// Set once the order doc is written, so retrying after a cancelled/failed
  /// card payment (same checkout visit — e.g. a declined card) reuses it
  /// instead of writing a duplicate order every time "Place Order" is
  /// tapped again.
  OrderEntity? _order;

  Future<void> _onOrderPlaceRequested(CheckoutOrderPlaceRequested event, Emitter<CheckoutState> emit) async {
    emit(CheckoutState(isPlacingOrder: true, placedOrder: _order));

    var order = _order;
    if (order == null) {
      final cartItems = _cartBloc.state.items;
      final totals = CartTotals.compute(_cartBloc.state.itemTotal);

      final result = await _placeOrderUseCase(
        PlaceOrderParams(
          cartItems: cartItems,
          totals: totals,
          paymentMethod: event.paymentMethod,
          addressLine: event.addressLine,
          addressPhone: event.addressPhone,
          addressReceiverName: event.addressReceiverName,
        ),
      );

      final placed = result.match((failure) {
        emit(CheckoutState(errorMessage: failure.message));
        return null;
      }, (o) => o);
      if (placed == null) return;

      order = placed;
      _order = placed;
    }

    if (!event.requiresCardPayment) {
      // Cash on Delivery — done immediately, exactly as before Stripe existed.
      _cartBloc.add(const CartCleared());
      emit(CheckoutState(placedOrder: order, paymentConfirmed: true));
      return;
    }

    final intentResult = await _createPaymentIntentUseCase(order.id);
    intentResult.match(
      (failure) => emit(CheckoutState(placedOrder: order, errorMessage: failure.message)),
      (clientSecret) =>
          emit(CheckoutState(placedOrder: order, isPlacingOrder: true, pendingPaymentClientSecret: clientSecret)),
    );
  }

  void _onPaymentConfirmed(CheckoutPaymentConfirmed event, Emitter<CheckoutState> emit) {
    _cartBloc.add(const CartCleared());
    emit(CheckoutState(placedOrder: _order, paymentConfirmed: true));
  }

  void _onPaymentFailed(CheckoutPaymentFailed event, Emitter<CheckoutState> emit) {
    emit(CheckoutState(placedOrder: _order, errorMessage: event.message));
  }

  void _onPaymentCanceled(CheckoutPaymentCanceled event, Emitter<CheckoutState> emit) {
    emit(CheckoutState(placedOrder: _order));
  }
}
