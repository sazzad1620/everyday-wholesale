import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/toast.dart';
import '../../../../shared/widgets/coming_soon_view.dart';
import '../../../../shared/widgets/dialogs/confirm_dialog.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../bloc/admin_product_list_bloc.dart';
import '../bloc/admin_product_list_event.dart';
import '../bloc/admin_product_list_state.dart';

/// Full product CRUD (minus photo upload, still Phase 5's second pass) —
/// mirrors [AdminCategoriesPage]'s structure closely: add/edit push
/// [AdminProductFormPage] on the root navigator, delete confirms first.
class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminProductListBloc>()..add(const AdminProductListRequested()),
      child: const _ProductListView(),
    );
  }
}

class _ProductListView extends StatelessWidget {
  const _ProductListView();

  Future<void> _openForm(BuildContext context, {ProductEntity? product}) async {
    final bloc = context.read<AdminProductListBloc>();
    final saved = await context.push<bool>(RoutePaths.adminProductForm, extra: product);
    if (saved == true) {
      bloc.add(const AdminProductListRequested());
    }
  }

  Future<void> _confirmDelete(BuildContext context, ProductEntity product) async {
    final bloc = context.read<AdminProductListBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.delete_product_title'.tr(),
      message: 'admin.delete_product_message'.tr(namedArgs: {'name': product.name}),
      confirmLabel: 'admin.delete'.tr(),
      cancelLabel: 'admin.cancel'.tr(),
    );
    if (confirmed) {
      bloc.add(AdminProductDeleteRequested(product.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminProductListBloc, AdminProductListState>(
      listenWhen: (previous, current) => previous.isDeleting && !current.isDeleting,
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppToast.show(context, state.errorMessage!, type: ToastType.error);
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(child: Text('admin.nav_products'.tr(), style: AppTextStyles.headline)),
                  Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openForm(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'admin.add_product'.tr(),
                              style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AdminProductListState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.products.isEmpty) {
      return ComingSoonView(
        icon: Icons.error_outline_rounded,
        title: 'common.generic_error'.tr(),
        message: state.errorMessage!,
      );
    }
    if (state.products.isEmpty) {
      return ComingSoonView(
        icon: Icons.inventory_2_outlined,
        title: 'admin.products_empty_title'.tr(),
        message: 'admin.products_empty_message'.tr(),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      itemCount: state.products.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final product = state.products[index];
        return _ProductTile(
          product: product,
          onTap: () => _openForm(context, product: product),
          onDelete: () => _confirmDelete(context, product),
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap, required this.onDelete});

  final ProductEntity product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      '${formatYen(product.price)} · ${product.unit}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (!product.inStock)
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'product.out_of_stock'.tr(),
                    style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
