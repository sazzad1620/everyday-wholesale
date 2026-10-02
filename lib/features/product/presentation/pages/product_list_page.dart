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
import '../../../home/presentation/widgets/subcategory_chip_strip.dart';
import '../../domain/entities/product_entity.dart';
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
/// filtered-out page's siblings, carried along so the chip row above the
/// products can show them without re-fetching the category.
typedef ProductListExtra = ({
  LocalizedText categoryName,
  LocalizedText subcategoryName,
  List<SubcategoryEntity> subcategories,
});

/// A category's products. When the category has subcategories, a row of
/// picture chips ("All" + one per subcategory) sits above the products;
/// tapping a chip filters them in place — no new page — and the breadcrumb
/// follows. [subcategoryId] (from the `browse/:subcategoryId` route) only
/// decides which chip starts selected.
class ProductListPage extends StatefulWidget {
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

  /// The category's subcategories — the chips above the products. When the
  /// route carries none (deep link, refresh, language switch) the resolver
  /// fills them in from the category cache.
  final List<SubcategoryEntity> subcategories;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late final ProductListBloc _bloc;

  /// The selected chip; null is "All".
  String? _subcategoryId;

  /// What the grid showed last, kept on screen (dimmed) while the next
  /// subcategory loads so the page doesn't jump.
  List<ProductEntity>? _lastProducts;

  @override
  void initState() {
    super.initState();
    _subcategoryId = widget.subcategoryId;
    _bloc = getIt<ProductListBloc>()
      ..add(
        ProductListStarted(widget.categoryId, subcategoryId: _subcategoryId),
      );
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _select(String? subcategoryId) {
    if (subcategoryId == _subcategoryId) return;
    setState(() => _subcategoryId = subcategoryId);
    _bloc.add(
      ProductListStarted(widget.categoryId, subcategoryId: subcategoryId),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Names travel as `LocalizedText` (not resolved strings) so the trail
    // re-renders in the new language if the user switches while here. When
    // there's no `extra` (deep link, refresh, or the switcher's remount) the
    // resolver fills the names and subcategories from the category cache.
    return CategoryContextResolver(
      categoryId: widget.categoryId,
      subcategoryId: widget.subcategoryId,
      categoryName: widget.categoryName,
      subcategoryName: widget.subcategoryName,
      subcategories: widget.subcategories,
      builder: (context, ctx) => _buildPage(context, ctx),
    );
  }

  /// The selected chip's name — looked up in the list, since the route's own
  /// name only covers the chip the page opened on.
  LocalizedText? _selectedName(CategoryContext ctx) {
    final id = _subcategoryId;
    if (id == null) return null;
    for (final sub in ctx.subcategories) {
      if (sub.id == id) return sub.name;
    }
    return id == widget.subcategoryId ? ctx.subcategoryName : null;
  }

  Widget _buildPage(BuildContext context, CategoryContext ctx) {
    final categoryText = ctx.categoryName;
    final categoryLabel = context.localized(categoryText);
    final subcategories = ctx.subcategories;
    final selectedName = _selectedName(ctx);

    final breadcrumbItems = _subcategoryId == null
        ? [BreadcrumbItem(label: categoryLabel, onTap: () {}, isCurrent: true)]
        : [
            BreadcrumbItem(label: categoryLabel, onTap: () => _select(null)),
            BreadcrumbItem(
              label: selectedName == null
                  ? _subcategoryId!
                  : context.localized(selectedName),
              onTap: () {},
              isCurrent: true,
            ),
          ];

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
                // Breadcrumb lives inside the content column, not spanning
                // the full page above the sidebar — so the sidebar starts
                // right below the header on every page, same as Home's.
                child: Column(
                  children: [
                    BreadcrumbBar(items: breadcrumbItems),
                    Expanded(
                      child: ResponsiveContentContainer(
                        child: ListView(
                          // Extra bottom space = the floating bottom nav
                          // (+ system bar), so the last row scrolls clear of
                          // it while content still passes behind it.
                          padding: EdgeInsets.only(
                            top: AppSpacing.md,
                            bottom:
                                AppSpacing.lg +
                                MediaQuery.paddingOf(context).bottom,
                          ),
                          children: [
                            if (subcategories.isNotEmpty) ...[
                              SubcategoryChipStrip(
                                subcategories: subcategories,
                                selectedId: _subcategoryId,
                                onSelected: _select,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                child: Text(
                                  selectedName == null
                                      ? 'product.all_category_products'.tr(
                                          namedArgs: {
                                            'categoryName': categoryLabel,
                                          },
                                        )
                                      : context.localized(selectedName),
                                  style: AppTextStyles.title,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            BlocBuilder<ProductListBloc, ProductListState>(
                              bloc: _bloc,
                              builder: (context, state) => _products(
                                context,
                                state,
                                categoryText,
                                selectedName,
                                subcategories,
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
          ],
        ),
      ),
    );
  }

  Widget _products(
    BuildContext context,
    ProductListState state,
    LocalizedText categoryName,
    LocalizedText? subcategoryName,
    List<SubcategoryEntity> subcategories,
  ) {
    if (state is ProductListError) {
      return Padding(
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
              state.message.tr(),
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final loaded = state is ProductListLoaded;
    if (loaded) _lastProducts = state.products;
    final products = loaded ? state.products : _lastProducts;

    if (products == null) {
      return const SizedBox(height: 240, child: Center(child: AppLoader()));
    }

    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Center(
          child: Text(
            'product.empty'.tr(),
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    // While the next subcategory loads, the previous products stay (faded and
    // untouchable) instead of the page collapsing to a spinner.
    return IgnorePointer(
      ignoring: !loaded,
      child: AnimatedOpacity(
        opacity: loaded ? 1 : 0.45,
        duration: const Duration(milliseconds: 160),
        child: ProductGrid(
          products: products,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onTap: (product) => context.push(
            RoutePaths.productDetail(widget.categoryId, product.id),
            extra: (
              categoryName: categoryName,
              subcategoryId: _subcategoryId,
              subcategoryName: subcategoryName,
              subcategories: subcategories,
            ),
          ),
        ),
      ),
    );
  }
}
