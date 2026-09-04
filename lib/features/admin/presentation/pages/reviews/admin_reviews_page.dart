import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/di/injection_container.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_spacing.dart';
import '../../../../../shared/theme/app_text_styles.dart';
import '../../../../../shared/widgets/coming_soon_view.dart';
import '../../../../../shared/widgets/product_image.dart';
import '../../../../../shared/widgets/star_rating.dart';
import '../../../../review/domain/entities/review_entity.dart';
import '../../bloc/reviews/admin_review_list_bloc.dart';
import '../../bloc/reviews/admin_review_list_event.dart';
import '../../bloc/reviews/admin_review_list_state.dart';

/// Read-only listing of every review submitted across every product/customer
/// — "who reviewed what". Last of the five admin sections.
class AdminReviewsPage extends StatelessWidget {
  const AdminReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminReviewListBloc>()..add(const AdminReviewListRequested()),
      child: const _AdminReviewListView(),
    );
  }
}

class _AdminReviewListView extends StatelessWidget {
  const _AdminReviewListView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text('admin.nav_user_reviews'.tr(), style: AppTextStyles.headline),
        ),
        Expanded(
          child: BlocBuilder<AdminReviewListBloc, AdminReviewListState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.errorMessage != null && state.reviews.isEmpty) {
                return ComingSoonView(
                  icon: Icons.error_outline_rounded,
                  title: 'common.generic_error'.tr(),
                  message: state.errorMessage!,
                );
              }
              if (state.reviews.isEmpty) {
                return ComingSoonView(
                  icon: Icons.reviews_outlined,
                  title: 'admin.reviews_empty_title'.tr(),
                  message: 'admin.reviews_empty_message'.tr(),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                itemCount: state.reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => _AdminReviewTile(review: state.reviews[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminReviewTile extends StatelessWidget {
  const _AdminReviewTile({required this.review});

  final ReviewEntity review;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 48, height: 48, child: ProductImage(imageUrl: review.productImageUrl)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.productName,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'admin.reviewed_by'.tr(namedArgs: {'name': review.reviewerName}),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    StarRating(rating: review.rating.toDouble(), size: 14),
                    const Spacer(),
                    Text(
                      DateFormat.yMMMd().format(review.createdAt),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
