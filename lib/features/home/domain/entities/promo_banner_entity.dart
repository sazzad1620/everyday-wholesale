import 'package:equatable/equatable.dart';

/// One admin-uploaded home-page banner. [order] is the carousel position
/// (ascending); [storagePath] is kept alongside the public [imageUrl] so
/// deleting a banner can also remove its file from Storage.
class PromoBannerEntity extends Equatable {
  const PromoBannerEntity({
    required this.id,
    required this.imageUrl,
    required this.storagePath,
    required this.order,
  });

  /// Carousel cap — keeps the rotation short enough that customers actually
  /// see every banner.
  static const int maxBanners = 10;

  final String id;
  final String imageUrl;
  final String storagePath;
  final int order;

  PromoBannerEntity copyWith({int? order}) =>
      PromoBannerEntity(id: id, imageUrl: imageUrl, storagePath: storagePath, order: order ?? this.order);

  @override
  List<Object?> get props => [id, imageUrl, storagePath, order];
}
