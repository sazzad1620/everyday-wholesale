import 'package:flutter/material.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/hover_lift.dart';
import '../../domain/entities/subcategory_entity.dart';
import 'category_card.dart';
import 'subcategory_card.dart';

class SubcategoryGrid extends StatelessWidget {
  const SubcategoryGrid({super.key, required this.subcategories, required this.onSubcategoryTap});

  final List<SubcategoryEntity> subcategories;
  final ValueChanged<SubcategoryEntity> onSubcategoryTap;

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
        itemCount: subcategories.length,
        gridDelegate: categoryTileGridDelegate(
          constraints.maxWidth - 2 * AppSpacing.md,
          MediaQuery.textScalerOf(context),
        ),
        itemBuilder: (context, index) {
          final subcategory = subcategories[index];
          return HoverLift(
            child: SubcategoryCard(subcategory: subcategory, index: index, onTap: () => onSubcategoryTap(subcategory)),
          );
        },
      ),
    );
  }
}
