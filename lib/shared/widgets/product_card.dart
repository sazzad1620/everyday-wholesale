import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/localization/localized_text.dart';
import '../../config/di/injection_container.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/cart/presentation/add_to_cart.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/cart/presentation/bloc/cart_event.dart';
import '../../features/cart/presentation/bloc/cart_state.dart';
import '../../features/product/domain/entities/product_entity.dart';
import '../../features/wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../features/wishlist/presentation/bloc/wishlist_event.dart';
import '../../features/wishlist/presentation/bloc/wishlist_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'product_image.dart';
import 'star_rating.dart';

const TextStyle _nameStyle = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.3);
const TextStyle _priceStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  height: 1.25,
  color: AppColors.primary,
);

// Fixed parts of the content under the image (see [ProductCard.contentHeight]).
const EdgeInsets _contentPadding = EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md + 8, AppSpacing.sm, AppSpacing.sm);
const double _nameToPriceGap = 2;
const double _priceToRatingGap = AppSpacing.xs;
const double _ratingRowHeight = 22; // wishlist icon 18 + 2×2 padding

double _lineHeight(TextScaler scaler, TextStyle style) => scaler.scale(style.fontSize!) * style.height!;

int _quantityInCart(CartState state, String productId) {
  for (final item in state.items) {
    if (item.product.id == productId) return item.quantity;
  }
  return 0;
}

/// The product tile used by both the product-list grid and the wishlist
/// grid — the two features share this instead of each keeping their own
/// copy, same reasoning as `CartTotalsBreakdown` living in `shared/`.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final ProductEntity product;
  final VoidCallback onTap;

  /// Exact height of everything below the square image, for the device's
  /// text size — grids size their rows from this so the card is always
  /// tight and never overflows, even with large accessibility text.
  static double contentHeight(TextScaler scaler) =>
      _contentPadding.vertical +
      _nameBoxHeight(scaler) +
      _nameToPriceGap +
      _lineHeight(scaler, _priceStyle) +
      _priceToRatingGap +
      _ratingRowHeight +
      2; // rounding slack across platforms' font metrics

  /// Two lines of name, reserved up front so shorter titles don't pull the
  /// price/rating row up with them.
  static double _nameBoxHeight(TextScaler scaler) => 2 * _lineHeight(scaler, _nameStyle) + 1;

  @override
  Widget build(BuildContext context) {
    final cartBloc = getIt<CartBloc>();
    final wishlistBloc = getIt<WishlistBloc>();

    // The floating cart button straddles the image/content boundary and
    // must be a *sibling* of the card's tap-to-detail InkWell, not a
    // descendant of it — otherwise part of the button falls outside the
    // inner Stack's own hit-test bounds (since that Stack only reports the
    // image's height) and taps there fall through to the card's onTap
    // instead of the button's. LayoutBuilder gives the image's rendered
    // height (card width, since it's a 1:1 square) so the button can be
    // positioned in the *outer* Stack, which is sized by the full card and
    // has no such gap.
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = constraints.maxWidth;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  // The photo tile is opaque white and hides ink, so a
                  // hover/press highlight would only ever tint the text
                  // half of the card. Hover feedback is `HoverLift`'s lift
                  // (see `ProductGrid`); taps need no overlay of their own.
                  overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                  splashColor: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: imageHeight,
                        child: ProductImage(imageUrl: product.thumbnailUrl),
                      ),
                      Padding(
                        padding: _contentPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: _nameBoxHeight(MediaQuery.textScalerOf(context)),
                              child: Text(
                                context.localized(product.name),
                                style: _nameStyle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: _nameToPriceGap),
                            Text(formatYen(product.price), style: _priceStyle, maxLines: 1),
                            const SizedBox(height: _priceToRatingGap),
                            SizedBox(
                              height: _ratingRowHeight,
                              child: Row(
                                children: [
                                  StarRating(rating: product.rating, size: 15),
                                  const Spacer(),
                                  BlocBuilder<WishlistBloc, WishlistState>(
                                    bloc: wishlistBloc,
                                    builder: (context, wishlistState) {
                                      final isWishlisted = wishlistState.contains(product.id);
                                      return InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () => isWishlisted
                                            ? wishlistBloc.add(WishlistItemRemoved(product.id))
                                            : wishlistBloc.add(WishlistItemAdded(product)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(2),
                                          child: Icon(
                                            isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                            size: 18,
                                            color: isWishlisted ? AppColors.primary : AppColors.textSecondary,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: AppSpacing.sm,
                top: imageHeight - 18,
                child: BlocBuilder<CartBloc, CartState>(
                  bloc: cartBloc,
                  builder: (context, state) {
                    final quantity = _quantityInCart(state, product.id);
                    // The pill grows out of the button (and shrinks back into
                    // it at 0) from the right edge, where both are pinned,
                    // instead of swapping instantly.
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      reverseDuration: const Duration(milliseconds: 160),
                      layoutBuilder: (current, previous) =>
                          Stack(alignment: Alignment.centerRight, children: [...previous, ?current]),
                      // Curves applied here, on the switcher's linear 0→1:
                      // a slight overshoot as the pill grows in, a plain
                      // ease as it shrinks away; the fade finishes early.
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: CurvedAnimation(parent: animation, curve: const Interval(0, 0.6)),
                        child: ScaleTransition(
                          scale: CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                            reverseCurve: Curves.easeIn,
                          ),
                          alignment: Alignment.centerRight,
                          child: child,
                        ),
                      ),
                      child: quantity == 0
                          // Same sign-in check + feedback as the detail page;
                          // no success toast here — the button turning into the
                          // quantity pill already shows it worked.
                          ? _AddToCartButton(
                              key: const ValueKey('add'),
                              onTap: () => addToCart(context, product, showSuccessToast: false),
                            )
                          : _QuantityPill(
                              key: const ValueKey('pill'),
                              quantity: quantity,
                              onIncrement: () => cartBloc.add(CartQuantityChanged(product.id, quantity + 1)),
                              onDecrement: () => cartBloc.add(CartQuantityChanged(product.id, quantity - 1)),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _QuantityPill extends StatelessWidget {
  const _QuantityPill({super.key, required this.quantity, required this.onIncrement, required this.onDecrement});

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove_rounded, onTap: onDecrement),
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            clipBehavior: Clip.antiAlias,
            // The number rolls up into place as it changes.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13),
              ),
            ),
          ),
          _StepperButton(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
