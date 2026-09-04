import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/route_paths.dart';
import '../../../features/home/domain/entities/category_entity.dart';
import '../../../features/home/presentation/utils/category_navigation.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// The category list shared by [CategoryDrawer] (mobile, inside a [Drawer])
/// and [DesktopSidebar] (tablet/desktop, always visible, no drawer to close)
/// — [onBeforeNavigate] lets the drawer pop itself before pushing; the
/// sidebar passes nothing since there's nothing to close.
class CategoryNavList extends StatelessWidget {
  const CategoryNavList({
    super.key,
    required this.categories,
    required this.tilePadding,
    this.onBeforeNavigate,
  });

  final List<CategoryEntity> categories;
  final EdgeInsetsGeometry tilePadding;
  final VoidCallback? onBeforeNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        for (final category in categories)
          _CategoryTile(category: category, padding: tilePadding, onBeforeNavigate: onBeforeNavigate),
      ],
    );
  }
}

class _CategoryTile extends StatefulWidget {
  const _CategoryTile({required this.category, required this.padding, this.onBeforeNavigate});

  final CategoryEntity category;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onBeforeNavigate;

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  static const double _fontSize = 13;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;

    if (category.subcategories.isEmpty) {
      return ListTile(
        contentPadding: widget.padding,
        title: Text(category.name, style: AppTextStyles.body.copyWith(fontSize: _fontSize)),
        onTap: () {
          widget.onBeforeNavigate?.call();
          navigateToCategory(context, category);
        },
      );
    }

    // Tapping the row only expands/collapses. "Show All" (once expanded) or
    // the landing page reached via the home grid are how you browse
    // everything in a category that has subcategories.
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: widget.padding,
        childrenPadding: EdgeInsets.zero,
        trailing: Icon(_expanded ? Icons.remove : Icons.add, color: AppColors.textPrimary),
        onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
        title: Text(
          category.name,
          style: AppTextStyles.body.copyWith(
            fontSize: _fontSize,
            fontWeight: _expanded ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        children: [
          ListTile(
            contentPadding: widget.padding,
            title: Text(
              'drawer.show_all'.tr(),
              style: AppTextStyles.body.copyWith(fontSize: _fontSize, fontStyle: FontStyle.italic),
            ),
            onTap: () {
              widget.onBeforeNavigate?.call();
              context.push(
                RoutePaths.categoryProducts(category.id),
                extra: (categoryName: category.name, subcategories: category.subcategories),
              );
            },
          ),
          for (final sub in category.subcategories)
            ListTile(
              contentPadding: widget.padding,
              title: Text(sub.name, style: AppTextStyles.body.copyWith(fontSize: _fontSize)),
              onTap: () {
                widget.onBeforeNavigate?.call();
                context.push(
                  RoutePaths.subcategoryProducts(category.id, sub.id),
                  extra: (categoryName: category.name, subcategoryName: sub.name, subcategories: category.subcategories),
                );
              },
            ),
        ],
      ),
    );
  }
}
