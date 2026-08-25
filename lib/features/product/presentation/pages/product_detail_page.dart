import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/loaders/app_loader.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../../shared/widgets/navigation/breadcrumb_bar.dart';
import '../../../account/presentation/widgets/account_sheet.dart';
import '../../../home/domain/entities/subcategory_entity.dart';
import '../bloc/product_detail_bloc.dart';
import '../bloc/product_detail_event.dart';
import '../bloc/product_detail_state.dart';
import '../widgets/product_detail_content.dart';

/// What `extra` carries on the `product/:productId` route — display-only
/// data needed to reconstruct the breadcrumb trail, since the URL only
/// carries ids. Mirrors `ProductListExtra`.
typedef ProductDetailExtra = ({
  String? categoryName,
  String? subcategoryId,
  String? subcategoryName,
  List<SubcategoryEntity> subcategories,
});

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    super.key,
    required this.categoryId,
    required this.productId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.subcategories = const [],
  });

  final String categoryId;
  final String productId;
  final String? categoryName;
  final String? subcategoryId;
  final String? subcategoryName;
  final List<SubcategoryEntity> subcategories;

  @override
  Widget build(BuildContext context) {
    final categoryLabel = categoryName ?? categoryId;

    return BlocProvider(
      create: (_) => getIt<ProductDetailBloc>()..add(ProductDetailStarted(productId)),
      child: ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          child: BlocBuilder<ProductDetailBloc, ProductDetailState>(
            builder: (context, state) {
              final breadcrumbItems = [
                BreadcrumbItem(
                  label: categoryLabel,
                  onTap: () => context.pushReplacement(
                    RoutePaths.categoryProducts(categoryId),
                    extra: (categoryName: categoryLabel, subcategories: subcategories),
                  ),
                ),
                if (subcategoryId != null)
                  BreadcrumbItem(
                    label: subcategoryName ?? subcategoryId!,
                    onTap: () => context.pushReplacement(
                      RoutePaths.subcategoryProducts(categoryId, subcategoryId!),
                      extra: (
                        categoryName: categoryLabel,
                        subcategoryName: subcategoryName ?? subcategoryId!,
                        subcategories: subcategories,
                      ),
                    ),
                  ),
                BreadcrumbItem(
                  label: state is ProductDetailLoaded ? state.product.name : '',
                  onTap: () {},
                  isCurrent: true,
                ),
              ];

              return Column(
                children: [
                  AppHeader(
                    onMenuTap: () => Scaffold.of(context).openDrawer(),
                    onAccountTap: () => openAccountMenu(context),
                  ),
                  BreadcrumbBar(items: breadcrumbItems),
                  Expanded(child: _ProductDetailBody(state: state)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({required this.state});

  final ProductDetailState state;

  @override
  Widget build(BuildContext context) {
    if (state is ProductDetailLoading || state is ProductDetailInitial) {
      return const Center(child: AppLoader());
    }

    if (state is ProductDetailError) {
      final message = (state as ProductDetailError).message;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final product = (state as ProductDetailLoaded).product;

    return SingleChildScrollView(child: ProductDetailContent(product: product));
  }
}
