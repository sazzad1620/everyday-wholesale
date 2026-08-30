import 'package:equatable/equatable.dart';

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
    this.ratingSum = 0,
    this.reviewCount = 0,
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

  /// Sum of every submitted review's star rating for this product —
  /// denormalized on the product doc (updated via `FieldValue.increment` the
  /// moment a review is submitted, see `ReviewRemoteDatasource.submitReview`)
  /// rather than derived from a live reviews query, so displaying a
  /// product's rating never needs a second read. [rating] divides this by
  /// [reviewCount] for display.
  final num ratingSum;

  final int reviewCount;

  /// 0 with no reviews yet — never null/blank, so every display site (star
  /// row, product card) can treat "not yet reviewed" as the zero case
  /// without a separate null check.
  double get rating => reviewCount == 0 ? 0 : ratingSum / reviewCount;

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
    ratingSum,
    reviewCount,
  ];
}
