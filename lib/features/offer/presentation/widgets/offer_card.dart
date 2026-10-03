import 'package:flutter/material.dart';

import '../../../../core/localization/localized_text.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../domain/entities/offer_entity.dart';

/// One offer in a list — optional banner image, title, body and posted date.
/// Used by the customer Offers page and (with [trailing]) the admin list.
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer, this.trailing});

  final OfferEntity offer;

  /// Admin-only slot (delete button) in the title row.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final imageUrl = offer.imageUrl;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: AppNetworkImage(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.inputFill),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(context.localized(offer.title), style: AppTextStyles.title)),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.localized(offer.body),
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  formatShortDate(context, offer.createdAt),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
