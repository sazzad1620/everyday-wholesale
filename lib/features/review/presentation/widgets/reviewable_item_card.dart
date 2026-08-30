import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/product_image.dart';
import '../../../../shared/widgets/star_rating_input.dart';
import '../../domain/entities/reviewable_item_entity.dart';

/// A single completed-order item waiting for a star rating. Tapping a star
/// submits immediately — no separate confirm step, matching how a quick
/// rating prompt normally works.
class ReviewableItemCard extends StatelessWidget {
  const ReviewableItemCard({super.key, required this.item, required this.isSubmitting, required this.onRate});

  final ReviewableItemEntity item;
  final bool isSubmitting;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(width: 56, height: 56, child: ProductImage(imageUrl: item.productImageUrl)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'my_reviews.purchased_on'.tr(namedArgs: {'date': DateFormat.yMMMMd().format(item.orderDate)}),
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1, color: AppColors.inputFill),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('my_reviews.rate_prompt'.tr(), style: AppTextStyles.body),
                  StarRatingInput(onChanged: onRate, enabled: !isSubmitting),
                ],
              ),
            ],
          ),
          if (isSubmitting)
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.surface.withValues(alpha: 0.7),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
    );
  }
}
