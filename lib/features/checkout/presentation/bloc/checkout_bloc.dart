import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/cart_totals.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../order/domain/usecases/place_order_usecase.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';

/// One per checkout visit (`@injectable`, not shared) — reads the live cart
/// straight from the shared `CartBloc` at submit time rather than holding
/// its own copy, and clears it via `CartCleared` once the order is placed.
@injectable
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc(this._placeOrderUseCase, this._cartBloc) : super(const CheckoutState()) {
    on<CheckoutOrderPlaceRequested>(_onOrderPlaceRequested);
  }

  final PlaceOrderUseCase _placeOrderUseCase;
  final CartBloc _cartBloc;

  Future<void> _onOrderPlaceRequested(CheckoutOrderPlaceRequested event, Emitter<CheckoutState> emit) async {
    emit(const CheckoutState(isPlacingOrder: true));

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

    result.match((failure) => emit(CheckoutState(errorMessage: failure.message)), (order) {
      emit(CheckoutState(placedOrder: order));
      _cartBloc.add(const CartCleared());
    });
  }
}
