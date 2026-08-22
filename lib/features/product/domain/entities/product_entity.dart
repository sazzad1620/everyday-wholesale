import 'package:equatable/equatable.dart';

import 'product_review_entity.dart';

class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.categoryId,
    required this.iconKey,
    required this.description,
    required this.condition,
    required this.origin,
    this.subcategoryId,
    this.imageUrl,
    this.inStock = true,
    this.reviews = const [],
  });

  final String id;
  final String name;

  /// Whole yen (¥), no decimals — matches the reference site's pricing style.
  final int price;
  final String unit;
  final String categoryId;
  final String iconKey;

  /// Longer copy shown in the Product Detail page's Description tab.
  final String description;

  /// E.g. "Fresh", "Frozen", "Dry / Packaged". Hardcoded mock data for now —
  /// becomes admin-editable once there's an admin UI, same spirit as [imageUrl].
  final String condition;

  /// E.g. "Bangladesh", "Brazil". Same admin-editable-later note as [condition].
  final String origin;

  /// Null for products in categories with no subcategories, or for products
  /// not yet assigned to one of their category's subcategories.
  final String? subcategoryId;

  /// Set by the admin when they upload a product photo. Null until then —
  /// presentation falls back to a generic placeholder.
  final String? imageUrl;

  final bool inStock;

  final List<ProductReviewEntity> reviews;

  /// Derived, not stored — a separate stored average could drift out of
  /// sync with [reviews] in mock data (or, later, in a real backend).
  double get rating {
    if (reviews.isEmpty) return 0;
    final total = reviews.fold<double>(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }

  int get reviewCount => reviews.length;

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    unit,
    categoryId,
    iconKey,
    description,
    condition,
    origin,
    subcategoryId,
    imageUrl,
    inStock,
    reviews,
  ];
}
