import '../../../../core/localization/localized_text.dart';
import '../../../../core/constants/countries.dart';
import '../../domain/entities/product_condition.dart';
import '../../domain/entities/product_entity.dart';

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
    super.images,
    super.inStock,
    super.ratingSum,
    super.reviewCount,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return ProductModel(
      id: id,
      name: LocalizedText.fromFirestore(map['name']),
      price: (map['price'] as num?)?.toInt() ?? 0,
      unit: map['unit'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      iconKey: map['iconKey'] as String? ?? '',
      description: LocalizedText.fromFirestore(map['description']),
      condition: ProductCondition.parse(map['condition'] as String?),
      origin: Countries.parse(map['origin'] as String?),
      subcategoryId: map['subcategoryId'] as String?,
      images: _readImages(map),
      inStock: map['inStock'] as bool? ?? true,
      ratingSum: (map['ratingSum'] as num?) ?? 0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Reads the new `images` array, falling back to the legacy singular
  /// `imageUrl` field so products written before the multi-image change
  /// still display their one photo.
  static List<String> _readImages(Map<String, dynamic> map) {
    final rawImages = map['images'];
    if (rawImages is List) return rawImages.whereType<String>().toList();
    final legacyImageUrl = map['imageUrl'] as String?;
    return legacyImageUrl == null ? const [] : [legacyImageUrl];
  }

  Map<String, dynamic> toMap() => {
    'name': name.toMap(),
    'price': price,
    'unit': unit,
    'categoryId': categoryId,
    'iconKey': iconKey,
    'description': description.toMap(),
    'condition': condition.code,
    'origin': origin,
    'subcategoryId': subcategoryId,
    'images': images,
    'inStock': inStock,
    'ratingSum': ratingSum,
    'reviewCount': reviewCount,
  };
}
