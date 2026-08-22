import 'package:flutter/material.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../../domain/entities/subcategory_entity.dart';
import 'subcategory_card.dart';

class SubcategoryGrid extends StatelessWidget {
  const SubcategoryGrid({super.key, required this.subcategories, required this.onSubcategoryTap});

  final List<SubcategoryEntity> subcategories;
  final ValueChanged<SubcategoryEntity> onSubcategoryTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subcategories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final subcategory = subcategories[index];
        return SubcategoryCard(subcategory: subcategory, index: index, onTap: () => onSubcategoryTap(subcategory));
      },
    );
  }
}
