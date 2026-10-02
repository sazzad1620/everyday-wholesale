import 'package:equatable/equatable.dart';

import '../../domain/entities/cart_item_entity.dart';

class CartState extends Equatable {
  const CartState({this.items = const [], this.syncErrorKey, this.syncErrorCount = 0});

  final List<CartItemEntity> items;

  /// Translation key of the last failed background save, if any. Changes
  /// are shown instantly and saved afterwards; when a save fails the cart is
  /// reloaded from Firestore and this tells the UI to say so.
  final String? syncErrorKey;

  /// Bumped on every failed save, so the same error twice still notifies.
  final int syncErrorCount;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  int get itemTotal => items.fold(0, (sum, item) => sum + item.lineTotal);

  CartState copyWith({List<CartItemEntity>? items, String? syncErrorKey, int? syncErrorCount}) => CartState(
    items: items ?? this.items,
    syncErrorKey: syncErrorKey ?? this.syncErrorKey,
    syncErrorCount: syncErrorCount ?? this.syncErrorCount,
  );

  @override
  List<Object?> get props => [items, syncErrorKey, syncErrorCount];
}
