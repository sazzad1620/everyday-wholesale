import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_network_image.dart';
import 'image_fade_in.dart';

/// A product's photo on a plain white tile, or — until an admin uploads one —
/// one plain generic placeholder so it reads as "no image set yet" rather
/// than a designed icon.
///
/// Every product photo in the app (cards, detail page, cart, orders, search,
/// reviews, admin) goes through this, with **one** padding rule: the photo is
/// fitted inside the tile (never cropped) with [insetFraction] of the tile's
/// shorter side as space on every edge — so a 64 px cart thumbnail and a
/// 600 px detail image have the same proportional breathing room. Uploads are
/// trimmed and have plain backgrounds whitened (see `ProductImageCleaner`),
/// which is what makes that padding the *only* margin around a product.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.imageUrl, this.radius = 0, this.bordered = false});

  final String? imageUrl;

  /// Corner radius of the tile. Leave `0` where the tile is flush inside a
  /// card that already supplies its own rounding and clipping.
  final double radius;

  /// Draws a hairline border, for standalone tiles (detail page, cart, lists)
  /// where a white tile would otherwise dissolve into the white page. Inside
  /// a product card the card's own shadow is the frame, so it stays off there.
  final bool bordered;

  /// Space around the photo, as a share of the tile's shorter side.
  static const double insetFraction = 0.08;

  static final Color _borderColor = Colors.black.withValues(alpha: 0.08);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: bordered ? Border.all(color: _borderColor) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shorterSide = constraints.biggest.shortestSide;
            final inset = shorterSide.isFinite ? shorterSide * insetFraction : 0.0;
            return switch (imageUrl) {
              null => const _Placeholder(),
              // Real admin uploads will be `https://` (Firebase Storage) URLs;
              // a bundled asset path is only ever a local demo stand-in.
              final url => Padding(
                padding: EdgeInsets.all(inset),
                child: url.startsWith('http')
                    ? AppNetworkImage(
                        url,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        // Falls back to the same "no image" placeholder on a
                        // load failure (e.g. no network) instead of Flutter's
                        // default broken-image icon with raw exception text.
                        frameBuilder: imageFadeIn,
                        errorBuilder: (context, error, stackTrace) => const _Placeholder(),
                      )
                    : Image.asset(url, fit: BoxFit.contain, width: double.infinity, height: double.infinity),
              ),
            };
          },
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: AppColors.surface, child: Center(child: Icon(Icons.image_outlined, size: 32, color: Colors.black26)));
}
