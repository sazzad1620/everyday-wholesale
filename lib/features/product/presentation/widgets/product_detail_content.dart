import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/snack_utils.dart';
import '../../../../shared/widgets/product_image.dart';
import '../../../../shared/widgets/quantity_stepper.dart';
import '../../../../shared/widgets/star_rating.dart';
import '../../domain/entities/product_entity.dart';
import 'product_detail_tabs.dart';
import 'product_highlight_boxes.dart';
import 'product_info_row.dart';

/// Quantity here is local to the page — not backed by a shared cart yet.
/// Once the real Cart feature lands, swap the local `_quantity` state for
/// `CartBloc` state, matching the same placeholder pattern used by the
/// product card's floating add-to-cart control.
class ProductDetailContent extends StatefulWidget {
  const ProductDetailContent({super.key, required this.product});

  final ProductEntity product;

  @override
  State<ProductDetailContent> createState() => _ProductDetailContentState();
}

class _ProductDetailContentState extends State<ProductDetailContent> {
  int _quantity = 1;

  void _increment() => setState(() => _quantity++);

  void _decrement() => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1);

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(aspectRatio: 1, child: ProductImage(imageUrl: product.imageUrl)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(product.name, style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatYen(product.price),
            style: AppTextStyles.title.copyWith(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              StarRating(rating: product.rating, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                product.reviewCount == 0
                    ? 'product.no_reviews_yet_title'.tr()
                    : 'product.review_count'.tr(namedArgs: {'count': '${product.reviewCount}'}),
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              _StockPill(inStock: product.inStock),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ProductInfoRow(weight: product.unit, condition: product.condition, origin: product.origin),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              QuantityStepper(quantity: _quantity, onIncrement: _increment, onDecrement: _decrement),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _AddToCartButton(onTap: () => showComingSoonSnackBar(context, 'Cart'))),
              const SizedBox(width: AppSpacing.sm),
              _WishlistIconButton(onTap: () => showComingSoonSnackBar(context, 'Wishlist')),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const ProductHighlightBoxes(),
          const SizedBox(height: AppSpacing.lg),
          ProductDetailTabs(product: product),
        ],
      ),
    );
  }
}

class _StockPill extends StatelessWidget {
  const _StockPill({required this.inStock});

  final bool inStock;

  @override
  Widget build(BuildContext context) {
    final color = inStock ? AppColors.primary : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            inStock ? 'product.in_stock'.tr() : 'product.out_of_stock'.tr(),
            style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'product.add_to_cart'.tr(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishlistIconButton extends StatelessWidget {
  const _WishlistIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Icon(Icons.favorite_border_rounded, color: AppColors.textSecondary, size: 20),
        ),
      ),
    );
  }
}
