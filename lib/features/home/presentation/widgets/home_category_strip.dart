import 'package:flutter/material.dart';

import '../../../../core/localization/localized_text.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/category_palette.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/image_fade_in.dart';
import '../../domain/entities/category_entity.dart';

const double _circle = 64;
const double _pictureZoom = 1.2;
// Room a name gets when the row doesn't scroll: enough for a bold two-word
// name ("Masala Mixes") on one line, so it wraps the same whether or not the
// chip is selected.
const double _itemWidth = 84;

/// Width of one item in a sideways row of [itemCount] [CategoryCircleItem]s
/// across [viewportWidth].
///
/// When everything fits, each item gets the full 84 px its name needs. When
/// the row scrolls, items are sized so a whole number of them plus half of
/// the next fit — the cut-off item is what shows the row scrolls.
double categoryCirclePitch(double viewportWidth, int itemCount) {
  final usable = viewportWidth - AppSpacing.md;
  if (itemCount * _itemWidth <= usable) return _itemWidth;
  final whole = (usable / _itemWidth).floor().clamp(1, 99);
  return usable / (whole + 0.5);
}

const TextStyle _labelStyle = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.2);

double _labelHeight(TextScaler scaler) => 2 * scaler.scale(_labelStyle.fontSize!) * _labelStyle.height! + 1;

/// Height of a row of [CategoryCircleItem]s at the device's text size.
double categoryCircleRowHeight(TextScaler scaler) => _circle + AppSpacing.sm + _labelHeight(scaler) + AppSpacing.xs;

/// One round picture with its name underneath — a category on the home page,
/// a subcategory chip on a category page. The picture is the one uploaded in
/// the admin (never a guessed icon); without one it shows the same neutral
/// placeholder as everywhere else. A bundled asset (the Most Everyday badge)
/// is shown whole instead of cropped.
class CategoryCircleItem extends StatelessWidget {
  const CategoryCircleItem({
    super.key,
    required this.label,
    required this.imageUrl,
    required this.colorIndex,
    required this.onTap,
    this.selected = false,
    this.icon,
    this.width = defaultWidth,
  });

  final String label;
  final String? imageUrl;

  /// Which tint of the category palette the circle uses.
  final int colorIndex;
  final VoidCallback onTap;

  /// Highlighted with a green ring and bold green name.
  final bool selected;

  /// Shown instead of a picture (e.g. the "All" chip).
  final IconData? icon;

  /// Slot width of an item when the row doesn't size them itself (the wrapped
  /// layout on wide screens).
  static const double defaultWidth = _itemWidth;

  /// Slot width in a row (see [categoryCirclePitch]).
  final double width;

  @override
  Widget build(BuildContext context) {
    final labelHeight = _labelHeight(MediaQuery.textScalerOf(context));

    return SizedBox(
      width: width,
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: _circle,
                  height: _circle,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: categoryColorFor(colorIndex),
                    border: Border.all(
                      color: selected ? AppColors.primary : categoryBorderColorFor(colorIndex),
                      width: selected ? 2.5 : 1.2,
                    ),
                  ),
                  child: icon != null ? Icon(icon, size: 28, color: AppColors.primary) : _picture(),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: labelHeight,
                  child: Text(
                    label,
                    style: _labelStyle.copyWith(
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _picture() {
    const placeholder = Center(child: Icon(Icons.image_outlined, size: 24, color: Colors.black26));
    final url = imageUrl;
    if (url == null) return placeholder;
    if (!url.startsWith('http')) {
      return Padding(
        padding: const EdgeInsets.all(5),
        child: Image.asset(url, fit: BoxFit.contain),
      );
    }
    // Zoomed in a little: uploaded pictures usually carry their own white
    // margin, which inside a small circle read as a gap around the subject.
    // The circle's clip cuts the overflow.
    return Transform.scale(
      scale: _pictureZoom,
      child: AppNetworkImage(
        url,
        fit: BoxFit.cover,
        width: _circle,
        height: _circle,
        frameBuilder: imageFadeIn,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

/// One row of round category pictures that scrolls sideways — the compact
/// replacement for the big category grid on phones.
///
/// The row is wider than the screen, so the last visible item is always cut
/// off at the edge — that is what tells people it scrolls.
class HomeCategoryStrip extends StatelessWidget {
  const HomeCategoryStrip({super.key, required this.categories, required this.onCategoryTap});

  final List<CategoryEntity> categories;
  final ValueChanged<CategoryEntity> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: categoryCircleRowHeight(MediaQuery.textScalerOf(context)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pitch = categoryCirclePitch(constraints.maxWidth, categories.length);
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: categories.length,
            itemBuilder: (context, index) => CategoryCircleItem(
              width: pitch,
              label: context.localized(categories[index].name),
              imageUrl: categories[index].imageUrl,
              colorIndex: index,
              onTap: () => onCategoryTap(categories[index]),
            ),
          );
        },
      ),
    );
  }
}
