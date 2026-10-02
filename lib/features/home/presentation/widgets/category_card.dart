import 'package:flutter/material.dart';

import '../../../../core/localization/localized_text.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/category_palette.dart';
import '../../../../shared/widgets/category_image.dart';
import '../../domain/entities/category_entity.dart';

/// Label under a category/subcategory tile's square image.
const TextStyle categoryTileLabelStyle = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.25);
const EdgeInsets _labelPadding = EdgeInsets.symmetric(vertical: 8, horizontal: 6);

/// Grid layout for category/subcategory tiles: square image plus a label
/// band tall enough for two lines at the device's text size. Sized exactly
/// (like `ProductGrid`) instead of a fixed aspect ratio, which left the
/// label too little room and cut the names off on narrow phones.
SliverGridDelegate categoryTileGridDelegate(double availableWidth, TextScaler scaler) {
  const maxTileWidth = 200.0;
  final columns = (availableWidth / maxTileWidth).ceil().clamp(1, 999);
  final tileWidth = (availableWidth - (columns - 1) * AppSpacing.sm) / columns;
  final labelHeight =
      _labelPadding.vertical + 2 * scaler.scale(categoryTileLabelStyle.fontSize!) * categoryTileLabelStyle.height! + 2;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    mainAxisSpacing: AppSpacing.sm,
    crossAxisSpacing: AppSpacing.sm,
    mainAxisExtent: tileWidth + labelHeight,
  );
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category, required this.index, required this.onTap});

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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
                // Fills the rest of the cell (sized for two lines by
                // [categoryTileGridDelegate]); one-line names sit centred.
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: labelColor,
                    alignment: Alignment.center,
                    padding: _labelPadding,
                    child: Text(
                      context.localized(category.name),
                      style: categoryTileLabelStyle,
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
