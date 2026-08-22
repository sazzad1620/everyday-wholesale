import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/route_paths.dart';
import '../../../features/home/domain/entities/category_entity.dart';
import '../../../features/home/presentation/utils/category_navigation.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'drawer_header_bar.dart';

const EdgeInsets _tilePadding = EdgeInsets.fromLTRB(
  DrawerHeaderBar.contentLeftPadding,
  4,
  AppSpacing.md,
  4,
);

/// Opened only from the bottom nav's "Category" item (see [MainShell]) — not
/// the hamburger menu, which opens [MainMenuDrawer] instead.
class CategoryDrawer extends StatelessWidget {
  const CategoryDrawer({super.key, required this.categories});

  final List<CategoryEntity> categories;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeaderBar(title: 'drawer.category_title'.tr()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [for (final category in categories) _CategoryTile(category: category)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  const _CategoryTile({required this.category});

  final CategoryEntity category;

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
        contentPadding: _tilePadding,
        title: Text(category.name, style: AppTextStyles.body.copyWith(fontSize: _fontSize)),
        onTap: () {
          Navigator.of(context).pop();
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
        tilePadding: _tilePadding,
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
            contentPadding: _tilePadding,
            title: Text(
              'drawer.show_all'.tr(),
              style: AppTextStyles.body.copyWith(fontSize: _fontSize, fontStyle: FontStyle.italic),
            ),
            onTap: () {
              Navigator.of(context).pop();
              context.push(
                RoutePaths.categoryProducts(category.id),
                extra: (categoryName: category.name, subcategories: category.subcategories),
              );
            },
          ),
          for (final sub in category.subcategories)
            ListTile(
              contentPadding: _tilePadding,
              title: Text(sub.name, style: AppTextStyles.body.copyWith(fontSize: _fontSize)),
              onTap: () {
                Navigator.of(context).pop();
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
