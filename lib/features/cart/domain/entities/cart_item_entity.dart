import 'package:equatable/equatable.dart';

import '../../../product/domain/entities/product_entity.dart';

/// Embeds a snapshot of the product rather than just its id — simplest
/// correct option while there's no backend to resolve products by id from.
class CartItemEntity extends Equatable {
  const CartItemEntity({required this.product, required this.quantity});

  final ProductEntity product;
  final int quantity;

  int get lineTotal => product.price * quantity;

  @override
  List<Object?> get props => [product, quantity];
}
