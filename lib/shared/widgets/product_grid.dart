import 'package:flutter/material.dart';

import '../../features/product/domain/entities/product_entity.dart';
import '../theme/app_spacing.dart';
import 'product_card.dart';

/// The product-card grid shared by [ProductListPage] and [WishlistPage].
///
/// Sizes each row by an *exact* pixel height — computed cell width (the
/// square image) plus [_contentHeight], the fixed height of everything
/// [ProductCard] renders below the image — rather than a proportional
/// `childAspectRatio`. A ratio scales the space left for that fixed-height
/// content with the card's width, so it only fits at whatever width it was
/// tuned for: too little room (an overflow) at any narrower width a wide
/// screen's extra columns produce, or a dead gap at the bottom for any
/// wider one. Computing the exact height here keeps the card exactly as
/// tight as it was at the original 2-column phone width, at every width.
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    required this.onTap,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<ProductEntity> products;
  final ValueChanged<ProductEntity> onTap;
  final EdgeInsets padding;

  /// Pass `true` (with [physics] set to [NeverScrollableScrollPhysics]) when
  /// this grid is nested inside another scrollable, same as [GridView.builder].
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  /// The widest a card is allowed to grow before another column fits — same
  /// role as `SliverGridDelegateWithMaxCrossAxisExtent.maxCrossAxisExtent`.
  static const double _maxCardWidth = 220;

  /// Padding(24 top + 8 bottom) + 2-line title(36) + spacing(2) + price
  /// line(~20) + spacing(4) + rating/wishlist row(22) in [ProductCard],
  /// plus a few px of margin for font-metric variance across platforms.
  static const double _contentHeight = 120;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = (constraints.maxWidth / _maxCardWidth).ceil().clamp(1, 999);
          final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * AppSpacing.sm) / crossAxisCount;

          return GridView.builder(
            shrinkWrap: shrinkWrap,
            physics: physics,
            itemCount: products.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisExtent: cardWidth + _contentHeight,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(product: product, onTap: () => onTap(product));
            },
          );
        },
      ),
    );
  }
}
