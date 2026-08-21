import 'package:equatable/equatable.dart';

import 'subcategory_entity.dart';

class CategoryEntity extends Equatable {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.iconKey,
    this.imageUrl,
    this.subcategories = const [],
  });

  final String id;
  final String name;
  final String iconKey;

  /// Set by the admin when they upload a category image. Null until then —
  /// presentation falls back to a placeholder built from [iconKey].
  final String? imageUrl;

  /// Empty for categories that don't break down further (e.g. Most Popular).
  /// When non-empty, presentation offers "pick a subcategory or browse all"
  /// instead of going straight to the product list.
  final List<SubcategoryEntity> subcategories;

  @override
  List<Object?> get props => [id, name, iconKey, imageUrl, subcategories];
}
