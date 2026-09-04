import 'package:equatable/equatable.dart';

import '../../../../home/domain/entities/category_entity.dart';

/// Single-class, flag-based state (matching [CheckoutState]) rather than
/// sealed variants — deleting a category must keep the current list on
/// screen (only [isDeleting] toggles) instead of swapping to a bare loading
/// state, which the variant style would force.
class CategoryListState extends Equatable {
  const CategoryListState({
    this.isLoading = false,
    this.categories = const [],
    this.errorMessage,
    this.isDeleting = false,
  });

  final bool isLoading;
  final List<CategoryEntity> categories;
  final String? errorMessage;
  final bool isDeleting;

  @override
  List<Object?> get props => [isLoading, categories, errorMessage, isDeleting];
}
