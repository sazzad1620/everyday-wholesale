import 'package:flutter/material.dart';

import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/category_palette.dart';
import '../../../../shared/widgets/category_image.dart';
import '../../domain/entities/subcategory_entity.dart';

/// Same visual language as [CategoryCard] — a subcategory is just a narrower
/// slice of a category, so it gets the same tile/border/label treatment.
class SubcategoryCard extends StatelessWidget {
  const SubcategoryCard({super.key, required this.subcategory, required this.index, required this.onTap});

  final SubcategoryEntity subcategory;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tileColor = categoryColorFor(index);
    final labelColor = categoryLabelColorFor(index);
    final borderColor = categoryBorderColorFor(index);
    final radius = BorderRadius.circular(16);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: CategoryImage(imageUrl: subcategory.imageUrl, backgroundColor: tileColor),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: labelColor,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: Text(
                      subcategory.name,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
