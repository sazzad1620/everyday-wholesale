import 'package:equatable/equatable.dart';

import '../../../product/domain/entities/product_entity.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class CartItemAdded extends CartEvent {
  const CartItemAdded(this.product, this.quantity);

  final ProductEntity product;
  final int quantity;

  @override
  List<Object?> get props => [product, quantity];
}

class CartQuantityChanged extends CartEvent {
  const CartQuantityChanged(this.productId, this.quantity);

  final String productId;
  final int quantity;

  @override
  List<Object?> get props => [productId, quantity];
}

class CartItemRemoved extends CartEvent {
  const CartItemRemoved(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

class CartCleared extends CartEvent {
  const CartCleared();
}
