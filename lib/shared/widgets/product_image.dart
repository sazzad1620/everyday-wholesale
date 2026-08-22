import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A product's photo, inset like [CategoryImage] — or, until an admin
/// uploads one, one plain generic placeholder so it reads as "no image set
/// yet" rather than a designed icon.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary.withValues(alpha: 0.06),
      child: switch (imageUrl) {
        null => const Center(
            child: Icon(Icons.image_outlined, size: 32, color: Colors.black26),
          ),
        // Real admin uploads will be `https://` (Firebase Storage) URLs; a
        // bundled asset path is only ever a local demo stand-in for one.
        // Inset with a little padding + its own rounding so the photo reads
        // as a card sitting on the tile, rather than filling it edge to edge
        // — matches CategoryImage's treatment of a real photo.
        final url => Padding(
            padding: const EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: url.startsWith('http')
                  ? Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                  : Image.asset(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            ),
          ),
      },
    );
  }
}
