import 'package:equatable/equatable.dart';

import '../../../product/domain/entities/product_entity.dart';

class WishlistState extends Equatable {
  const WishlistState({this.items = const []});

  final List<ProductEntity> items;

  bool contains(String productId) => items.any((item) => item.id == productId);

  @override
  List<Object?> get props => [items];
}
