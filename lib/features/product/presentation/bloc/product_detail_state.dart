import 'package:equatable/equatable.dart';

import '../../../review/domain/entities/review_entity.dart';
import '../../domain/entities/product_entity.dart';

abstract class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object?> get props => [];
}

class ProductDetailInitial extends ProductDetailState {
  const ProductDetailInitial();
}

class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

class ProductDetailLoaded extends ProductDetailState {
  const ProductDetailLoaded(this.product, {this.reviews = const []});

  final ProductEntity product;

  /// This product's individual reviews (name + stars, shown on the Review
  /// tab) — fetched alongside the product itself so the tab never needs its
  /// own separate load. Failing to fetch these isn't fatal to the page, so
  /// it just falls back to an empty list rather than failing the whole load.
  final List<ReviewEntity> reviews;

  @override
  List<Object?> get props => [product, reviews];
}

class ProductDetailError extends ProductDetailState {
  const ProductDetailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
