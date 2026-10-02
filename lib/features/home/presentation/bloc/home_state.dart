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

/// One category's product row on the home page.
class HomeCategoryRow extends Equatable {
  const HomeCategoryRow({required this.category, required this.products, required this.hasMore});

  final CategoryEntity category;
  final List<ProductEntity> products;

  /// True when the category may hold more than [products] shows, so the row
  /// ends with a "View all" card.
  final bool hasMore;

  @override
  List<Object?> get props => [category, products, hasMore];
}

class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.categories,
    required this.promoBanners,
    required this.mostPopularProducts,
    this.categoryRows = const [],
  });

  /// Already led by the virtual Most Popular category when
  /// [mostPopularProducts] is non-empty.
  final List<CategoryEntity> categories;
  final List<PromoBannerEntity> promoBanners;
  final List<ProductEntity> mostPopularProducts;

  /// One row per category that has products, in category order. Filled in a
  /// moment after the rest of the page (only with `kHomeShowsCategoryRows`).
  final List<HomeCategoryRow> categoryRows;

  @override
  List<Object?> get props => [categories, promoBanners, mostPopularProducts, categoryRows];
}

class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
