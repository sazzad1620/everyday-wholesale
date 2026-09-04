import 'package:equatable/equatable.dart';

import '../../../../product/domain/entities/product_entity.dart';

/// Flag-based state — matches [CategoryListState] so a delete-in-progress
/// keeps the current list on screen instead of blanking to a loading state.
class AdminProductListState extends Equatable {
  const AdminProductListState({
    this.isLoading = false,
    this.products = const [],
    this.errorMessage,
    this.isDeleting = false,
  });

  final bool isLoading;
  final List<ProductEntity> products;
  final String? errorMessage;
  final bool isDeleting;

  @override
  List<Object?> get props => [isLoading, products, errorMessage, isDeleting];
}
