import 'package:equatable/equatable.dart';

import '../../domain/entities/cart_item_entity.dart';

class CartState extends Equatable {
  const CartState({this.items = const []});

  final List<CartItemEntity> items;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  int get itemTotal => items.fold(0, (sum, item) => sum + item.lineTotal);

  @override
  List<Object?> get props => [items];
}
