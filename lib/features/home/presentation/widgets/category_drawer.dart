import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_paths.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/snack_utils.dart';
import '../../domain/entities/category_entity.dart';
import '../utils/category_navigation.dart';

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
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  Image.asset(AssetPaths.logo, height: 36),
                  const SizedBox(width: AppSpacing.sm),
                  Text('drawer.title'.tr(), style: AppTextStyles.title),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  for (final category in categories) _CategoryTile(category: category),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
                    child: Divider(height: 1),
                  ),
                  _FooterTile(
                    icon: Icons.info_outline_rounded,
                    label: 'drawer.about'.tr(),
                    onTap: () => showComingSoonSnackBar(context, 'drawer.about'.tr()),
                  ),
                  _FooterTile(
                    icon: Icons.call_outlined,
                    label: 'drawer.contact'.tr(),
                    onTap: () => showComingSoonSnackBar(context, 'drawer.contact'.tr()),
                  ),
                ],
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
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;

    if (category.subcategories.isEmpty) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        title: Text(category.name, style: AppTextStyles.body),
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
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: EdgeInsets.zero,
        trailing: Icon(_expanded ? Icons.remove : Icons.add, color: AppColors.textPrimary),
        onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
        title: Text(
          category.name,
          style: AppTextStyles.body.copyWith(fontWeight: _expanded ? FontWeight.w700 : FontWeight.w400),
        ),
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
            title: Text('drawer.show_all'.tr(), style: AppTextStyles.body.copyWith(fontStyle: FontStyle.italic)),
            onTap: () {
              Navigator.of(context).pop();
              context.push(RoutePaths.categoryProducts(category.id), extra: category.name);
            },
          ),
          for (final sub in category.subcategories)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              title: Text(sub.name, style: AppTextStyles.body),
              onTap: () {
                Navigator.of(context).pop();
                context.push(
                  RoutePaths.subcategoryProducts(category.id, sub.id),
                  extra: (categoryName: category.name, subcategoryName: sub.name),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _FooterTile extends StatelessWidget {
  const _FooterTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: AppTextStyles.body),
      onTap: onTap,
    );
  }
}
