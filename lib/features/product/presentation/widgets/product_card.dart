import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/snack_utils.dart';
import '../../../../shared/widgets/product_image.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../domain/entities/product_entity.dart';

int _quantityInCart(CartState state, String productId) {
  for (final item in state.items) {
    if (item.product.id == productId) return item.quantity;
  }
  return 0;
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final ProductEntity product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cartBloc = getIt<CartBloc>();

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: imageHeight, child: ProductImage(imageUrl: product.imageUrl)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md + 8, AppSpacing.sm, AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              // Reserves space for 2 lines up front so shorter
                              // titles don't pull the price/rating row up with them.
                              height: 36,
                              child: Text(
                                product.name,
                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatYen(product.price),
                              style: AppTextStyles.title.copyWith(color: AppColors.primary, fontSize: 16),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                for (var i = 0; i < 5; i++)
                                  const Icon(Icons.star_border_rounded, size: 15, color: AppColors.textSecondary),
                                const Spacer(),
                                InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => showComingSoonSnackBar(context, 'Wishlist'),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.favorite_border_rounded, size: 18, color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
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
                    return quantity == 0
                        ? _AddToCartButton(onTap: () => cartBloc.add(CartItemAdded(product, 1)))
                        : _QuantityPill(
                            quantity: quantity,
                            onIncrement: () => cartBloc.add(CartQuantityChanged(product.id, quantity + 1)),
                            onDecrement: () => cartBloc.add(CartQuantityChanged(product.id, quantity - 1)),
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
  const _AddToCartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 3)),
        ],
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
  const _QuantityPill({required this.quantity, required this.onIncrement, required this.onDecrement});

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
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
            child: Text(
              '$quantity',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13),
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
