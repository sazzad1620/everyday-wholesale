import '../../domain/entities/product_entity.dart';
import 'product_review_model.dart';

/// Mirrors a `products/{productId}` Firestore document. `id` is the
/// document ID, not a stored field.
class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
    required super.unit,
    required super.categoryId,
    required super.iconKey,
    required super.description,
    required super.condition,
    required super.origin,
    super.subcategoryId,
    super.imageUrl,
    super.inStock,
    super.reviews,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, {required String id}) {
    final rawReviews = map['reviews'] as List<dynamic>? ?? const [];
    return ProductModel(
      id: id,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      unit: map['unit'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      iconKey: map['iconKey'] as String? ?? '',
      description: map['description'] as String? ?? '',
      condition: map['condition'] as String? ?? '',
      origin: map['origin'] as String? ?? '',
      subcategoryId: map['subcategoryId'] as String?,
      imageUrl: map['imageUrl'] as String?,
      inStock: map['inStock'] as bool? ?? true,
      reviews: rawReviews.map((raw) => ProductReviewModel.fromMap(Map<String, dynamic>.from(raw as Map))).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'unit': unit,
    'categoryId': categoryId,
    'iconKey': iconKey,
    'description': description,
    'condition': condition,
    'origin': origin,
    'subcategoryId': subcategoryId,
    'imageUrl': imageUrl,
    'inStock': inStock,
    'reviews': reviews
        .map((r) => ProductReviewModel(reviewerName: r.reviewerName, rating: r.rating, comment: r.comment).toMap())
        .toList(),
  };
}
