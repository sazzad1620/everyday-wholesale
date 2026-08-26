import 'package:equatable/equatable.dart';

import '../../../product/domain/entities/product_entity.dart';

abstract class WishlistEvent extends Equatable {
  const WishlistEvent();

  @override
  List<Object?> get props => [];
}

class WishlistItemAdded extends WishlistEvent {
  const WishlistItemAdded(this.product);

  final ProductEntity product;

  @override
  List<Object?> get props => [product];
}

class WishlistItemRemoved extends WishlistEvent {
  const WishlistItemRemoved(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}
