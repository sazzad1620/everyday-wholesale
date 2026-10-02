import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../core/localization/localized_text.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/loaders/app_loader.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../../shared/widgets/navigation/desktop_body.dart';
import '../../../../shared/widgets/product_grid.dart';
import '../../../../shared/widgets/responsive_content_container.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../../core/utils/responsive/breakpoints.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/most_popular_category.dart';
import '../../domain/entities/subcategory_entity.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../../home_layout.dart';
import '../utils/category_navigation.dart';
import '../widgets/category_grid.dart';
import '../widgets/home_category_strip.dart';
import '../widgets/home_product_row.dart';
import '../widgets/home_promo_carousel.dart';

/// The home page previews this many Most Popular products; "View All" opens
/// the full category.
const int _homeMostPopularLimit = 12;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeBloc>()..add(const HomeStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

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
            AppHeader(
              onMenuTap: () => Scaffold.of(context).openDrawer(),
              onAccountTap: () => openAccountMenu(context),
            ),
            Expanded(
              child: DesktopBody(
                child: BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) => _HomeBody(state: state),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    if (state is HomeLoading || state is HomeInitial) {
      return const Center(child: AppLoader());
    }

    if (state is HomeError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('common.generic_error'.tr(), style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () =>
                    context.read<HomeBloc>().add(const HomeStarted()),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    final loaded = state as HomeLoaded;
    if (kHomeShowsCategoryRows) return _CategoryRowsHome(loaded: loaded);

    return ResponsiveContentContainer(
      child: ListView(
        // Extra bottom space = the floating bottom nav (+ system bar), so the
        // last row scrolls clear of it while content still passes behind it.
        padding: EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          if (loaded.promoBanners.isNotEmpty) ...[
            HomePromoCarousel(banners: loaded.promoBanners),
            const SizedBox(height: AppSpacing.lg),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'home.explore_categories'.tr(),
              style: AppTextStyles.title,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CategoryGrid(
            categories: loaded.categories,
            onCategoryTap: (category) => navigateToCategory(context, category),
          ),
          if (loaded.mostPopularProducts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'home.most_popular'.tr(),
                      style: AppTextStyles.title,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        navigateToCategory(context, mostPopularCategory),
                    child: Text('home.view_all'.tr()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ProductGrid(
              products: loaded.mostPopularProducts
                  .take(_homeMostPopularLimit)
                  .toList(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Opened "under" Most Popular so the breadcrumb leads back to
              // it, same as tapping the product inside that category.
              onTap: (product) => context.push(
                RoutePaths.productDetail(mostPopularCategoryId, product.id),
                extra: (
                  categoryName: mostPopularCategory.name,
                  subcategoryId: null,
                  subcategoryName: null,
                  subcategories: const <SubcategoryEntity>[],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Opens a product from a home-page row, the way the category's own page
/// does: the breadcrumb leads back to that category.
void _openProduct(
  BuildContext context,
  ProductEntity product,
  CategoryEntity category,
) {
  context.push(
    RoutePaths.productDetail(category.id, product.id),
    extra: (
      categoryName: category.name,
      subcategoryId: null,
      subcategoryName: null,
      subcategories: category.subcategories,
    ),
  );
}

/// The row-based home page (see [kHomeShowsCategoryRows]): banner, a strip
/// of category pictures (phones only — desktop has the sidebar), then
/// product rows: Most Everyday first, then one per category with products.
class _CategoryRowsHome extends StatelessWidget {
  const _CategoryRowsHome({required this.loaded});

  final HomeLoaded loaded;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;

    return ResponsiveContentContainer(
      child: ListView(
        padding: EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          if (loaded.promoBanners.isNotEmpty) ...[
            HomePromoCarousel(banners: loaded.promoBanners),
            const SizedBox(height: AppSpacing.md),
          ],
          if (!wide && loaded.categories.isNotEmpty) ...[
            HomeCategoryStrip(
              categories: loaded.categories,
              onCategoryTap: (category) =>
                  navigateToCategory(context, category),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (loaded.mostPopularProducts.isNotEmpty) ...[
            HomeProductRow(
              title: 'home.most_popular'.tr(),
              products: loaded.mostPopularProducts
                  .take(_homeMostPopularLimit)
                  .toList(),
              endWithViewAllCard:
                  loaded.mostPopularProducts.length > _homeMostPopularLimit,
              onViewAll: () => navigateToCategory(context, mostPopularCategory),
              onProductTap: (product) =>
                  _openProduct(context, product, mostPopularCategory),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          for (final row in loaded.categoryRows) ...[
            HomeProductRow(
              title: context.localized(row.category.name),
              products: row.products,
              endWithViewAllCard: row.hasMore,
              onViewAll: () => navigateToCategory(context, row.category),
              onProductTap: (product) =>
                  _openProduct(context, product, row.category),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
