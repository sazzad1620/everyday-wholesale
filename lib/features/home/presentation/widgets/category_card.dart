import 'package:flutter/material.dart';

import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/category_palette.dart';
import '../../../../shared/widgets/category_image.dart';
import '../../domain/entities/category_entity.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.index,
    required this.onTap,
  });

  final CategoryEntity category;
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Clipping lives on its own layer, sized to the full box — clipping via
      // the bordered Container's own clipBehavior instead would deflate the
      // clip rect by the border width, leaving a sliver of the page
      // background showing between the border and the tile/label fill.
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
                  child: CategoryImage(imageUrl: category.imageUrl, backgroundColor: tileColor),
                ),
                // Expanded, not a natural-height box — the grid cell's height
                // is fixed by its aspect ratio and won't exactly match the
                // image + label's natural height, so the label has to stretch
                // to the remainder or a gap shows below it.
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: labelColor,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: Text(
                      category.name,
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
