import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/snack_utils.dart';
import '../../../../shared/widgets/loaders/app_loader.dart';
import '../bloc/product_list_bloc.dart';
import '../bloc/product_list_event.dart';
import '../bloc/product_list_state.dart';
import '../widgets/product_card.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({
    super.key,
    required this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
  });

  final String categoryId;
  final String? categoryName;
  final String? subcategoryId;
  final String? subcategoryName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductListBloc>()
        ..add(ProductListStarted(categoryId, subcategoryId: subcategoryId)),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(subcategoryName ?? categoryName ?? categoryId)),
        body: BlocBuilder<ProductListBloc, ProductListState>(
          builder: (context, state) => _ProductListBody(state: state),
        ),
      ),
    );
  }
}

class _ProductListBody extends StatelessWidget {
  const _ProductListBody({required this.state});

  final ProductListState state;

  @override
  Widget build(BuildContext context) {
    if (state is ProductListLoading || state is ProductListInitial) {
      return const Center(child: AppLoader());
    }

    if (state is ProductListError) {
      final message = (state as ProductListError).message;
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

    final products = (state as ProductListLoaded).products;

    if (products.isEmpty) {
      return Center(
        child: Text('product.empty'.tr(), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(product: product, onTap: () => showComingSoonSnackBar(context, product.name));
      },
    );
  }
}
