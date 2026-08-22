import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.categoryId,
    required this.iconKey,
    this.subcategoryId,
    this.imageUrl,
  });

  final String id;
  final String name;

  /// Whole yen (¥), no decimals — matches the reference site's pricing style.
  final int price;
  final String unit;
  final String categoryId;
  final String iconKey;

  /// Null for products in categories with no subcategories, or for products
  /// not yet assigned to one of their category's subcategories.
  final String? subcategoryId;

  /// Set by the admin when they upload a product photo. Null until then —
  /// presentation falls back to a generic placeholder.
  final String? imageUrl;

  @override
  List<Object?> get props => [id, name, price, unit, categoryId, iconKey, subcategoryId, imageUrl];
}
