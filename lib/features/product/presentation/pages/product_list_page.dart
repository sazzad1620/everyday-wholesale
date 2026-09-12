import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../core/localization/localized_text.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/loaders/app_loader.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../../shared/widgets/navigation/breadcrumb_bar.dart';
import '../../../../shared/widgets/navigation/desktop_body.dart';
import '../../../../shared/widgets/product_grid.dart';
import '../../../../shared/widgets/responsive_content_container.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../home/domain/entities/subcategory_entity.dart';
import '../../../home/presentation/widgets/subcategory_grid.dart';
import '../bloc/product_list_bloc.dart';
import '../bloc/product_list_event.dart';
import '../bloc/product_list_state.dart';
import '../widgets/category_context_resolver.dart';

/// What `extra` carries on the `category/:categoryId` route.
typedef CategoryProductsExtra = ({
  LocalizedText? categoryName,
  List<SubcategoryEntity> subcategories,
});

/// What `extra` carries on the `browse/:subcategoryId` route — both names
/// are needed there since the path only has ids. `subcategories` is the
/// filtered-out page's siblings, carried along purely so a "back to
/// category" breadcrumb tap can restore the merged subcategory+product view
/// without re-fetching the category.
typedef ProductListExtra = ({
  LocalizedText categoryName,
  LocalizedText subcategoryName,
  List<SubcategoryEntity> subcategories,
});

class ProductListPage extends StatelessWidget {
  const ProductListPage({
    super.key,
    required this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.subcategories = const [],
  });

  final String categoryId;
  final LocalizedText? categoryName;
  final String? subcategoryId;
  final LocalizedText? subcategoryName;

  /// The category's subcategories — shown as a card grid above the products
  /// when `subcategoryId` is null (the top-level category view), so browsing
  /// a category and picking a subcategory happen on the same page instead of
  /// a separate landing page. Still threaded through even when filtered to
  /// one subcategory, purely so navigating back to the category restores
  /// that merged view (see [ProductListExtra]).
  final List<SubcategoryEntity> subcategories;

  @override
  Widget build(BuildContext context) {
    // Names travel as `LocalizedText` (not resolved strings) so the trail
    // re-renders in the new language if the user switches while here. When
    // there's no `extra` (deep link, refresh, or the switcher's remount) the
    // resolver fills the names and subcategories from the category cache.
    return CategoryContextResolver(
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      categoryName: categoryName,
      subcategoryName: subcategoryName,
      subcategories: subcategories,
      builder: (context, ctx) => _buildPage(context, ctx),
    );
  }

  Widget _buildPage(BuildContext context, CategoryContext ctx) {
    final categoryText = ctx.categoryName;
    final categoryLabel = context.localized(categoryText);
    final subcategoryLabel = ctx.subcategoryName == null ? subcategoryId : context.localized(ctx.subcategoryName!);
    final subcategories = ctx.subcategories;

    final breadcrumbItems = subcategoryId == null
        ? [BreadcrumbItem(label: categoryLabel, onTap: () {}, isCurrent: true)]
        : [
            BreadcrumbItem(
              label: categoryLabel,
              onTap: () => context.pushReplacement(
                RoutePaths.categoryProducts(categoryId),
                extra: (
                  categoryName: categoryText,
                  subcategories: subcategories,
                ),
              ),
            ),
            BreadcrumbItem(
              label: subcategoryLabel!,
              onTap: () {},
              isCurrent: true,
            ),
          ];

    return BlocProvider(
      create: (_) =>
          getIt<ProductListBloc>()
            ..add(ProductListStarted(categoryId, subcategoryId: subcategoryId)),
      child: ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                onMenuTap: () => Scaffold.of(context).openDrawer(),
                onAccountTap: () => openAccountMenu(context),
              ),
              Expanded(
                child: DesktopBody(
                  // Breadcrumb lives inside the content column, not spanning
                  // the full page above the sidebar — so the sidebar starts
                  // right below the header on every page, same as Home's.
                  child: Column(
                    children: [
                      BreadcrumbBar(items: breadcrumbItems),
                      Expanded(
                        child: BlocBuilder<ProductListBloc, ProductListState>(
                          builder: (context, state) => _ProductListBody(
                            state: state,
                            categoryId: categoryId,
                            categoryName: categoryText,
                            subcategoryId: subcategoryId,
                            subcategoryName: ctx.subcategoryName,
                            subcategories: subcategories,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductListBody extends StatelessWidget {
  const _ProductListBody({
    required this.state,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.subcategories,
  });

  final ProductListState state;
  final String categoryId;
  final LocalizedText categoryName;
  final String? subcategoryId;
  final LocalizedText? subcategoryName;
  final List<SubcategoryEntity> subcategories;

  @override
  Widget build(BuildContext context) {
    if (state is ProductListLoading || state is ProductListInitial) {
      return const Center(child: AppLoader());
    }

    if (state is ProductListError) {
      final message = (state as ProductListError).message.tr();
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
              Text(
                message,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final products = (state as ProductListLoaded).products;
    // Only the unfiltered, top-level category view shows the subcategory
    // grid — a subcategory-filtered view carries the same list along (see
    // [ProductListExtra]) purely for breadcrumb "back" navigation, not display.
    final showSubcategories = subcategoryId == null && subcategories.isNotEmpty;

    return ResponsiveContentContainer(
      child: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.lg,
        ),
        children: [
          if (showSubcategories) ...[
            SubcategoryGrid(
              subcategories: subcategories,
              onSubcategoryTap: (sub) => context.push(
                RoutePaths.subcategoryProducts(categoryId, sub.id),
                extra: (
                  categoryName: categoryName,
                  subcategoryName: sub.name,
                  subcategories: subcategories,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'product.all_category_products'.tr(
                  namedArgs: {'categoryName': context.localized(categoryName)},
                ),
                style: AppTextStyles.title,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Center(
                child: Text(
                  'product.empty'.tr(),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ProductGrid(
              products: products,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onTap: (product) => context.push(
                RoutePaths.productDetail(categoryId, product.id),
                extra: (
                  categoryName: categoryName,
                  subcategoryId: subcategoryId,
                  subcategoryName: subcategoryName,
                  subcategories: subcategories,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
