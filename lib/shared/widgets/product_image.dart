import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A product's photo, inset like [CategoryImage] — or, until an admin
/// uploads one, one plain generic placeholder so it reads as "no image set
/// yet" rather than a designed icon.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.imageUrl, this.padding = 10});

  final String? imageUrl;

  /// Inset around the real photo before its own rounding — the default
  /// matches [CategoryImage]'s "photo sitting on a card" treatment for
  /// grid/detail tiles. Compact contexts (small list-row thumbnails) should
  /// pass `0` so the photo fills the tile instead of shrinking further
  /// inside an already-small box.
  final double padding;

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
        final url => Padding(
            padding: EdgeInsets.all(padding),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: url.startsWith('http')
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      // Falls back to the same "no image" placeholder on a
                      // load failure (e.g. no network) instead of Flutter's
                      // default broken-image icon with raw exception text.
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.image_outlined, size: 32, color: Colors.black26)),
                    )
                  : Image.asset(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            ),
          ),
      },
    );
  }
}
