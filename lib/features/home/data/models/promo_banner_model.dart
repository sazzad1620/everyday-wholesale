import '../../domain/entities/promo_banner_entity.dart';

/// Mirrors a `banners/{bannerId}` Firestore document. `id` is the document
/// ID, not a stored field.
class PromoBannerModel extends PromoBannerEntity {
  const PromoBannerModel({
    required super.id,
    required super.imageUrl,
    required super.storagePath,
    required super.order,
  });

  factory PromoBannerModel.fromMap(Map<String, dynamic> map, {required String id}) => PromoBannerModel(
    id: id,
    imageUrl: map['imageUrl'] as String? ?? '',
    storagePath: map['storagePath'] as String? ?? '',
    order: (map['order'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toMap() => {'imageUrl': imageUrl, 'storagePath': storagePath, 'order': order};
}
