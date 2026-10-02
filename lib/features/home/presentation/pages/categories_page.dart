import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/loaders/app_loader.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../../shared/widgets/navigation/categories_cache.dart';
import '../../../../shared/widgets/navigation/desktop_body.dart';
import '../../../../shared/widgets/responsive_content_container.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../domain/entities/category_entity.dart';
import '../utils/category_navigation.dart';
import '../widgets/category_grid.dart';

/// The bottom nav's "Category" tab: every category as a picture tile (the
/// same tiles the home page used to show as a grid). Every tile opens its
/// category page, where the subcategories are a row of picture chips above
/// the products.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        // Bottom handled by the scroll view's padding instead, so content can
        // run behind the floating bottom nav (StandaloneShellScaffold.extendBody).
        bottom: false,
        child: Column(
          children: [
            AppHeader(onMenuTap: () => Scaffold.of(context).openDrawer(), onAccountTap: () => openAccountMenu(context)),
            const Expanded(child: DesktopBody(child: _CategoriesBody())),
          ],
        ),
      ),
    );
  }
}

class _CategoriesBody extends StatelessWidget {
  const _CategoriesBody();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryEntity>>(
      future: cachedCategories(),
      builder: (context, snapshot) {
        final categories = snapshot.data;
        if (categories == null) return const Center(child: AppLoader());
        if (categories.isEmpty) {
          return Center(child: Text('common.generic_error'.tr(), style: AppTextStyles.body));
        }
        return ResponsiveContentContainer(
          child: ListView(
            padding: EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('drawer.category_title'.tr(), style: AppTextStyles.headline),
              ),
              const SizedBox(height: AppSpacing.md),
              CategoryGrid(categories: categories, onCategoryTap: (category) => navigateToCategory(context, category)),
            ],
          ),
        );
      },
    );
  }
}
