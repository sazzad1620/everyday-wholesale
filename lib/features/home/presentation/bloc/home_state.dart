import 'package:equatable/equatable.dart';

import '../../../product/domain/entities/product_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/promo_banner_entity.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  const HomeLoaded({required this.categories, required this.promoBanners, required this.mostPopularProducts});

  /// Already led by the virtual Most Popular category when
  /// [mostPopularProducts] is non-empty.
  final List<CategoryEntity> categories;
  final List<PromoBannerEntity> promoBanners;
  final List<ProductEntity> mostPopularProducts;

  @override
  List<Object?> get props => [categories, promoBanners, mostPopularProducts];
}

class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
