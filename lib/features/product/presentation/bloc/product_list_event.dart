import 'package:equatable/equatable.dart';

abstract class ProductListEvent extends Equatable {
  const ProductListEvent();

  @override
  List<Object?> get props => [];
}

class ProductListStarted extends ProductListEvent {
  const ProductListStarted(this.categoryId, {this.subcategoryId});

  final String categoryId;
  final String? subcategoryId;

  @override
  List<Object?> get props => [categoryId, subcategoryId];
}
