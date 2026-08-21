import 'package:flutter/material.dart';

/// A category's photo, or — until an admin uploads one — one plain, generic
/// placeholder (same for every category, deliberately not themed) so it
/// reads clearly as "no image set yet" rather than a designed icon.
class CategoryImage extends StatelessWidget {
  const CategoryImage({
    super.key,
    required this.imageUrl,
    required this.backgroundColor,
  });

  final String? imageUrl;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: switch (imageUrl) {
        null => const Center(
            child: Icon(Icons.image_outlined, size: 32, color: Colors.black26),
          ),
        // Inset with a little padding + its own rounding so the photo reads
        // as a card sitting on the tile, rather than filling it edge to edge.
        final url => Padding(
            padding: const EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              // Real admin uploads will be `https://` (Firebase Storage)
              // URLs; a bundled asset path is only ever a local demo
              // stand-in for one.
              child: url.startsWith('http')
                  ? Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                  : Image.asset(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            ),
          ),
      },
    );
  }
}
