import 'package:equatable/equatable.dart';

import '../../../../product/domain/entities/product_entity.dart';

/// Flag-based state — matches [CategoryListState] so a delete-in-progress
/// keeps the current list on screen instead of blanking to a loading state.
///
/// [products] is everything the admin has; [visibleProducts] is what the list
/// shows — the same products filtered and ordered by [query] (identical to
/// [products] while the search box is empty).
class AdminProductListState extends Equatable {
  const AdminProductListState({
    this.isLoading = false,
    this.products = const [],
    this.visibleProducts = const [],
    this.query = '',
    this.errorMessage,
    this.isDeleting = false,
  });

  final bool isLoading;
  final List<ProductEntity> products;
  final List<ProductEntity> visibleProducts;
  final String query;
  final String? errorMessage;
  final bool isDeleting;

  bool get isSearching => query.trim().isNotEmpty;

  @override
  List<Object?> get props => [isLoading, products, visibleProducts, query, errorMessage, isDeleting];
}
