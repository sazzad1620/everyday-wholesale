import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../features/home/domain/entities/category_entity.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'category_nav_list.dart';
import 'drawer_header_bar.dart';

const EdgeInsets _tilePadding = EdgeInsets.fromLTRB(
  DrawerHeaderBar.contentLeftPadding,
  4,
  AppSpacing.md,
  4,
);

/// Opened only from the bottom nav's "Category" item (see [MainShell]) — not
/// the hamburger menu, which opens [MainMenuDrawer] instead. On tablet/desktop
/// this content is shown inline via [DesktopSidebar] instead, so this widget
/// only ever renders on mobile.
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
              child: CategoryNavList(
                categories: categories,
                tilePadding: _tilePadding,
                onBeforeNavigate: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
