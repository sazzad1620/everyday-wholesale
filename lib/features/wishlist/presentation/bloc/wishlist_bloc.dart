import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/add_to_wishlist_usecase.dart';
import '../../domain/usecases/remove_from_wishlist_usecase.dart';
import 'wishlist_event.dart';
import 'wishlist_state.dart';

/// Registered `@lazySingleton` (not the usual per-page `@injectable`) so the
/// wishlist page, the bottom-nav tab, and every heart icon across the app
/// (product cards, product detail) all react to the same shared state — same
/// reasoning as `CartBloc`.
@lazySingleton
class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  WishlistBloc(this._addToWishlist, this._removeFromWishlist) : super(const WishlistState()) {
    on<WishlistItemAdded>(_onItemAdded);
    on<WishlistItemRemoved>(_onItemRemoved);
  }

  final AddToWishlistUseCase _addToWishlist;
  final RemoveFromWishlistUseCase _removeFromWishlist;

  Future<void> _onItemAdded(WishlistItemAdded event, Emitter<WishlistState> emit) async {
    final result = await _addToWishlist(event.product);
    result.match((_) {}, (items) => emit(WishlistState(items: items)));
  }

  Future<void> _onItemRemoved(WishlistItemRemoved event, Emitter<WishlistState> emit) async {
    final result = await _removeFromWishlist(event.productId);
    result.match((_) {}, (items) => emit(WishlistState(items: items)));
  }
}
