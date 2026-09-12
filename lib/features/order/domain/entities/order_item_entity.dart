import 'package:equatable/equatable.dart';

import '../../../../core/localization/localized_text.dart';

/// A frozen snapshot of a cart item at the moment an order was placed —
/// deliberately decoupled from `ProductEntity`/`CartItemEntity` so a later
/// price change or product deletion never alters historical order data.
class OrderItemEntity extends Equatable {
  const OrderItemEntity({
    required this.productId,
    required this.name,
    required this.price,
    required this.unit,
    required this.quantity,
    this.imageUrl,
  });

  final String productId;
  final LocalizedText name;
  final int price;
  final String unit;
  final int quantity;
  final String? imageUrl;

  int get lineTotal => price * quantity;

  @override
  List<Object?> get props => [productId, name, price, unit, quantity, imageUrl];
}
