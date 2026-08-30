import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/toast.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/product_image.dart';
import '../../../../shared/widgets/quantity_stepper.dart';
import '../../../../shared/widgets/star_rating.dart';
import '../../../../shared/widgets/dialogs/sign_in_dialog.dart';
import '../../../auth/presentation/bloc/account_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../review/domain/entities/review_entity.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../../wishlist/presentation/bloc/wishlist_event.dart';
import '../../../wishlist/presentation/bloc/wishlist_state.dart';
import '../../domain/entities/product_entity.dart';
import 'product_detail_tabs.dart';
import 'product_highlight_boxes.dart';
import 'product_info_row.dart';

/// `_quantity` here is how many to add on the next tap — not the cart's own
/// count for this product (that lives in `CartBloc`). Tapping "Add to Cart"
/// dispatches into the shared cart and resets this back to 1.
class ProductDetailContent extends StatefulWidget {
  const ProductDetailContent({super.key, required this.product, this.reviews = const []});

  final ProductEntity product;
  final List<ReviewEntity> reviews;

  @override
  State<ProductDetailContent> createState() => _ProductDetailContentState();
}

class _ProductDetailContentState extends State<ProductDetailContent> {
  int _quantity = 1;

  void _increment() => setState(() => _quantity++);

  void _decrement() => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1);

  void _addToCart(BuildContext context, ProductEntity product) {
    if (!getIt<AccountBloc>().state.isLoggedIn) {
      AppToast.show(context, 'cart.sign_in_required'.tr(), type: ToastType.error);
      showSignInDialog(context);
      return;
    }
    getIt<CartBloc>().add(CartItemAdded(product, _quantity));
    AppToast.show(context, 'product.added_to_cart'.tr(), type: ToastType.success);
    setState(() => _quantity = 1);
  }

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
              Expanded(
                child: PrimaryButton(
                  label: 'product.add_to_cart'.tr(),
                  icon: Icons.shopping_cart_outlined,
                  onTap: () => _addToCart(context, product),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _WishlistIconButton(product: product),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const ProductHighlightBoxes(),
          const SizedBox(height: AppSpacing.lg),
          ProductDetailTabs(product: product, reviews: widget.reviews),
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

class _WishlistIconButton extends StatelessWidget {
  const _WishlistIconButton({required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final wishlistBloc = getIt<WishlistBloc>();

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
        child: BlocBuilder<WishlistBloc, WishlistState>(
          bloc: wishlistBloc,
          builder: (context, state) {
            final isWishlisted = state.contains(product.id);
            return InkWell(
              customBorder: const CircleBorder(),
              onTap: () => isWishlisted
                  ? wishlistBloc.add(WishlistItemRemoved(product.id))
                  : wishlistBloc.add(WishlistItemAdded(product)),
              child: Icon(
                isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isWishlisted ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            );
          },
        ),
      ),
    );
  }
}
