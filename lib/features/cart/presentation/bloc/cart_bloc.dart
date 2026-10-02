import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/usecases/clear_cart_usecase.dart';
import '../../domain/usecases/get_cart_usecase.dart';
import '../../domain/usecases/increment_cart_item_usecase.dart';
import '../../domain/usecases/set_cart_item_quantity_usecase.dart';
import 'cart_event.dart';
import 'cart_state.dart';

/// Registered `@lazySingleton` (not the usual per-page `@injectable`) so the
/// cart page, the bottom-nav badge, and every "Add to Cart" button across
/// the app all react to the same shared state — same reasoning as
/// `AccountBloc`. Stays in sync with which account is signed in via
/// [AuthRepository.authStateChanges] — each account has its own Firestore
/// cart, so switching accounts (or signing out) reloads/empties it.
///
/// **Optimistic updates:** every change is applied to the state (and so the
/// screen) the moment it's tapped, then saved to Firestore in the
/// background. Previously each tap waited for a read + write + a reload of
/// the whole cart *and every product in it* before anything moved on
/// screen. Saves run one at a time, in tap order, and rapid taps on the same
/// product are coalesced into a single write of the latest quantity. If a
/// save fails, the true cart is reloaded from Firestore and
/// [CartState.syncErrorKey] is set so the UI can say so.
@lazySingleton
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(
    this._authRepository,
    this._getCart,
    this._setQuantity,
    this._increment,
    this._clearCart,
  ) : super(const CartState()) {
    on<CartItemAdded>(_onItemAdded);
    on<CartQuantityChanged>(_onQuantityChanged);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartCleared>(_onCleared);
    on<CartSyncFailed>(_onSyncFailed);
    on<CartReloadRequested>(_onReloadRequested);
    on<CartAuthStateChanged>(_onAuthStateChanged);

    _authSubscription = _authRepository.authStateChanges.listen(
      (user) => add(CartAuthStateChanged(isSignedIn: user != null)),
    );
  }

  final AuthRepository _authRepository;
  final GetCartUseCase _getCart;
  final SetCartItemQuantityUseCase _setQuantity;
  final IncrementCartItemUseCase _increment;
  final ClearCartUseCase _clearCart;

  late final StreamSubscription<void> _authSubscription;

  /// Tail of the background-save queue — each save starts after the
  /// previous one finishes, so Firestore sees changes in tap order.
  Future<void> _writes = Future.value();
  int _pendingWrites = 0;

  /// Latest wanted quantity per product whose save is queued but not yet
  /// sent — further taps just update this instead of queueing more writes.
  final Map<String, int> _queuedQuantities = {};

  bool _isSignedIn = false;
  bool _isLoading = false;
  bool _changedWhileLoading = false;

  // ------------------------------------------------------------ changes

  void _onItemAdded(CartItemAdded event, Emitter<CartState> emit) {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.product.id == event.product.id);
    if (index >= 0) {
      final quantity = items[index].quantity + event.quantity;
      items[index] = CartItemEntity(product: items[index].product, quantity: quantity);
      emit(state.copyWith(items: items));
      _queueQuantity(event.product.id, quantity);
    } else {
      items.add(CartItemEntity(product: event.product, quantity: event.quantity));
      emit(state.copyWith(items: items));
      // Not in the local cart: add atomically rather than overwrite, in case
      // the saved cart (still loading right after sign-in) already has it.
      _enqueue(() => _increment(IncrementCartItemParams(productId: event.product.id, by: event.quantity)));
    }
  }

  void _onQuantityChanged(CartQuantityChanged event, Emitter<CartState> emit) =>
      _applyQuantity(event.productId, event.quantity, emit);

  void _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) => _applyQuantity(event.productId, 0, emit);

  void _applyQuantity(String productId, int quantity, Emitter<CartState> emit) {
    final items = [
      for (final item in state.items)
        if (item.product.id != productId)
          item
        else if (quantity > 0)
          CartItemEntity(product: item.product, quantity: quantity),
    ];
    emit(state.copyWith(items: items));
    _queueQuantity(productId, quantity);
  }

  void _onCleared(CartCleared event, Emitter<CartState> emit) {
    _queuedQuantities.clear();
    emit(state.copyWith(items: const []));
    _enqueue(() => _clearCart(const NoParams()));
  }

  // ------------------------------------------------------- background saves

  void _queueQuantity(String productId, int quantity) {
    final alreadyQueued = _queuedQuantities.containsKey(productId);
    _queuedQuantities[productId] = quantity;
    if (alreadyQueued) return;
    _enqueue(() {
      final latest = _queuedQuantities.remove(productId);
      // Superseded by "clear cart" while waiting in the queue.
      if (latest == null) return Future.value(const Right<Failure, void>(null));
      return _setQuantity(SetCartItemQuantityParams(productId: productId, quantity: latest));
    });
  }

  void _enqueue(Future<Either<Failure, void>> Function() write) {
    if (_isLoading) _changedWhileLoading = true;
    _pendingWrites++;
    _writes = _writes.then((_) async {
      final result = await write();
      _pendingWrites--;
      result.match((failure) => add(CartSyncFailed(failure.messageKey)), (_) {});
    });
  }

  // ------------------------------------------------------------ loading

  Future<void> _onSyncFailed(CartSyncFailed event, Emitter<CartState> emit) async {
    // A save that fails because the user just signed out isn't worth a
    // message — the cart is being emptied anyway.
    if (!_isSignedIn) return;
    emit(state.copyWith(syncErrorKey: event.messageKey, syncErrorCount: state.syncErrorCount + 1));
    await _reloadWhenIdle(emit);
  }

  Future<void> _onReloadRequested(CartReloadRequested event, Emitter<CartState> emit) => _reloadWhenIdle(emit);

  /// Replaces the optimistic state with Firestore's — only once no saves
  /// are pending, so it can't briefly undo a change still being saved.
  Future<void> _reloadWhenIdle(Emitter<CartState> emit) async {
    await _writes;
    if (!_isSignedIn || _pendingWrites > 0) return;
    final result = await _getCart(const NoParams());
    if (_pendingWrites > 0) return;
    result.match((_) {}, (items) => emit(state.copyWith(items: items)));
  }

  Future<void> _onAuthStateChanged(CartAuthStateChanged event, Emitter<CartState> emit) async {
    _isSignedIn = event.isSignedIn;
    if (!event.isSignedIn) {
      _queuedQuantities.clear();
      emit(const CartState());
      return;
    }
    _isLoading = true;
    _changedWhileLoading = false;
    final result = await _getCart(const NoParams());
    _isLoading = false;
    // Tapped while the cart was loading: that snapshot is already stale —
    // reload once those saves are done instead of showing it.
    if (_changedWhileLoading) {
      add(const CartReloadRequested());
      return;
    }
    result.match((_) {}, (items) => emit(state.copyWith(items: items)));
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
