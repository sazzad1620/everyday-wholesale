import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/coming_soon_view.dart';
import '../../../../shared/widgets/star_rating.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_review_entity.dart';

/// Description / Review / FAQ. A manual segmented tab bar rather than
/// [TabBarView] — a [TabBarView] needs a bounded height, which conflicts
/// with living inside the page's outer scroll view.
class ProductDetailTabs extends StatefulWidget {
  const ProductDetailTabs({super.key, required this.product});

  final ProductEntity product;

  @override
  State<ProductDetailTabs> createState() => _ProductDetailTabsState();
}

class _ProductDetailTabsState extends State<ProductDetailTabs> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final labels = ['product.tab_description'.tr(), 'product.tab_review'.tr(), 'product.tab_faq'.tr()];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(child: _TabSegment(label: labels[i], selected: i == _selectedIndex, onTap: () => setState(() => _selectedIndex = i))),
          ],
        ),
        const Divider(height: 1, color: AppColors.inputFill),
        const SizedBox(height: AppSpacing.md),
        switch (_selectedIndex) {
          0 => _DescriptionTab(description: widget.product.description),
          1 => _ReviewTab(reviews: widget.product.reviews),
          _ => const _FaqTab(),
        },
      ],
    );
  }
}

class _TabSegment extends StatelessWidget {
  const _TabSegment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(height: 3, color: selected ? AppColors.primary : Colors.transparent),
          ],
        ),
      ),
    );
  }
}

class _DescriptionTab extends StatelessWidget {
  const _DescriptionTab({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Text(description, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, height: 1.5));
  }
}

class _ReviewTab extends StatelessWidget {
  const _ReviewTab({required this.reviews});

  final List<ProductReviewEntity> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return ComingSoonView(
        icon: Icons.rate_review_outlined,
        title: 'product.no_reviews_yet_title'.tr(),
        message: 'product.no_reviews_yet_message'.tr(),
      );
    }

    return Column(
      children: [
        for (final review in reviews) ...[
          _ReviewCard(review: review),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ProductReviewEntity review;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(review.reviewerName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
              ),
              StarRating(rating: review.rating, size: 14),
            ],
          ),
          const SizedBox(height: 4),
          Text(review.comment, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _FaqTab extends StatelessWidget {
  const _FaqTab();

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('product.faq.delivery_q'.tr(), 'product.faq.delivery_a'.tr()),
      ('product.faq.halal_q'.tr(), 'product.faq.halal_a'.tr()),
      ('product.faq.payment_q'.tr(), 'product.faq.payment_a'.tr()),
      ('product.faq.returns_q'.tr(), 'product.faq.returns_a'.tr()),
    ];

    return Column(
      children: [
        for (final (question, answer) in entries) ...[
          _FaqCard(question: question, answer: answer),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          title: Text(question, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(answer, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
