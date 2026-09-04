import 'package:flutter/material.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../../domain/entities/category_entity.dart';
import 'category_card.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, required this.categories, required this.onCategoryTap});

  final List<CategoryEntity> categories;
  final ValueChanged<CategoryEntity> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      // Max-extent (not a fixed count) so column count grows with available
      // width on its own — 2 columns at phone width, more as the sidebar
      // and wider viewport free up room, no breakpoint branching needed.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(
          category: category,
          index: index,
          onTap: () => onCategoryTap(category),
        );
      },
    );
  }
}
