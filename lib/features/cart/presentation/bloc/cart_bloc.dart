import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/add_to_cart_usecase.dart';
import '../../domain/usecases/clear_cart_usecase.dart';
import '../../domain/usecases/remove_from_cart_usecase.dart';
import '../../domain/usecases/update_cart_quantity_usecase.dart';
import 'cart_event.dart';
import 'cart_state.dart';

/// Registered `@lazySingleton` (not the usual per-page `@injectable`) so the
/// cart page, the bottom-nav badge, and every "Add to Cart" button across
/// the app all react to the same shared state — same reasoning as
/// `AccountBloc`.
@lazySingleton
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._addToCart, this._updateQuantity, this._removeFromCart, this._clearCart) : super(const CartState()) {
    on<CartItemAdded>(_onItemAdded);
    on<CartQuantityChanged>(_onQuantityChanged);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartCleared>(_onCleared);
  }

  final AddToCartUseCase _addToCart;
  final UpdateCartQuantityUseCase _updateQuantity;
  final RemoveFromCartUseCase _removeFromCart;
  final ClearCartUseCase _clearCart;

  Future<void> _onItemAdded(CartItemAdded event, Emitter<CartState> emit) async {
    final result = await _addToCart(AddToCartParams(product: event.product, quantity: event.quantity));
    result.match((_) {}, (items) => emit(CartState(items: items)));
  }

  Future<void> _onQuantityChanged(CartQuantityChanged event, Emitter<CartState> emit) async {
    final result = await _updateQuantity(UpdateCartQuantityParams(productId: event.productId, quantity: event.quantity));
    result.match((_) {}, (items) => emit(CartState(items: items)));
  }

  Future<void> _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) async {
    final result = await _removeFromCart(event.productId);
    result.match((_) {}, (items) => emit(CartState(items: items)));
  }

  Future<void> _onCleared(CartCleared event, Emitter<CartState> emit) async {
    final result = await _clearCart(const NoParams());
    result.match((_) {}, (items) => emit(CartState(items: items)));
  }
}
