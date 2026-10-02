import 'package:flutter/material.dart';

import '../../../../shared/widgets/auto_slide_carousel.dart';
import '../../../../shared/widgets/product_image.dart';

/// Product photo gallery for the detail page — the same [AutoSlideCarousel]
/// as the home banners (auto-play, mouse drag, hover arrows, clickable
/// dots), so a multi-photo product can be browsed on desktop as well as by
/// swiping. With 0 or 1 photos it's a single static tile.
class ProductImageGallery extends StatelessWidget {
  const ProductImageGallery({super.key, required this.images});

  final List<String> images;

  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    if (images.length <= 1) {
      return AspectRatio(
        aspectRatio: 1,
        child: ProductImage(imageUrl: images.isEmpty ? null : images.first, radius: _radius, bordered: true),
      );
    }

    return AutoSlideCarousel(
      itemCount: images.length,
      aspectRatio: 1,
      viewportRadius: BorderRadius.circular(_radius),
      itemBuilder: (context, index, isActive) =>
          ProductImage(imageUrl: images[index], radius: _radius, bordered: true),
    );
  }
}
