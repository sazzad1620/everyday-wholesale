import 'package:flutter/material.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/hover_lift.dart';
import '../../domain/entities/category_entity.dart';
import 'category_card.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, required this.categories, required this.onCategoryTap});

  final List<CategoryEntity> categories;
  final ValueChanged<CategoryEntity> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    // Horizontal padding is inside the GridView, so the tiles get the width
    // minus 2 × md.
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        // Lets a hovered card (HoverLift) rise without its top edge being cut.
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: categoryTileGridDelegate(
          constraints.maxWidth - 2 * AppSpacing.md,
          MediaQuery.textScalerOf(context),
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          return HoverLift(
            child: CategoryCard(category: category, index: index, onTap: () => onCategoryTap(category)),
          );
        },
      ),
    );
  }
}
