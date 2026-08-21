import 'package:equatable/equatable.dart';

import '../../domain/entities/product_entity.dart';

abstract class ProductListState extends Equatable {
  const ProductListState();

  @override
  List<Object?> get props => [];
}

class ProductListInitial extends ProductListState {
  const ProductListInitial();
}

class ProductListLoading extends ProductListState {
  const ProductListLoading();
}

class ProductListLoaded extends ProductListState {
  const ProductListLoaded(this.products);

  final List<ProductEntity> products;

  @override
  List<Object?> get props => [products];
}

class ProductListError extends ProductListState {
  const ProductListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
