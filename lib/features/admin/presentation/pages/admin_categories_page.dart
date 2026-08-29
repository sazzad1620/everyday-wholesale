import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/category_icons.dart';
import '../../../../shared/utils/toast.dart';
import '../../../../shared/widgets/coming_soon_view.dart';
import '../../../../shared/widgets/dialogs/confirm_dialog.dart';
import '../../../home/domain/entities/category_entity.dart';
import '../bloc/category_list_bloc.dart';
import '../bloc/category_list_event.dart';
import '../bloc/category_list_state.dart';

/// Full category CRUD — list with add/edit/delete, replacing the previous
/// "coming soon" placeholder. Add/edit opens [AdminCategoryFormPage] pushed
/// on the root navigator; delete confirms via [showConfirmDialog] first.
class AdminCategoriesPage extends StatelessWidget {
  const AdminCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CategoryListBloc>()..add(const CategoryListRequested()),
      child: const _CategoryListView(),
    );
  }
}

class _CategoryListView extends StatelessWidget {
  const _CategoryListView();

  Future<void> _openForm(BuildContext context, {CategoryEntity? category}) async {
    final bloc = context.read<CategoryListBloc>();
    final saved = await context.push<bool>(RoutePaths.adminCategoryForm, extra: category);
    if (saved == true) {
      bloc.add(const CategoryListRequested());
    }
  }

  Future<void> _confirmDelete(BuildContext context, CategoryEntity category) async {
    final bloc = context.read<CategoryListBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.delete_category_title'.tr(),
      message: 'admin.delete_category_message'.tr(namedArgs: {'name': category.name}),
      confirmLabel: 'admin.delete'.tr(),
      cancelLabel: 'admin.cancel'.tr(),
    );
    if (confirmed) {
      bloc.add(CategoryDeleteRequested(category.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryListBloc, CategoryListState>(
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
                  Expanded(child: Text('admin.nav_categories'.tr(), style: AppTextStyles.headline)),
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
                              'admin.add_category'.tr(),
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

  Widget _buildBody(BuildContext context, CategoryListState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.categories.isEmpty) {
      return ComingSoonView(
        icon: Icons.error_outline_rounded,
        title: 'common.generic_error'.tr(),
        message: state.errorMessage!,
      );
    }
    if (state.categories.isEmpty) {
      return ComingSoonView(
        icon: Icons.category_outlined,
        title: 'admin.categories_empty_title'.tr(),
        message: 'admin.categories_empty_message'.tr(),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      itemCount: state.categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final category = state.categories[index];
        return _CategoryTile(
          category: category,
          onTap: () => _openForm(context, category: category),
          onDelete: () => _confirmDelete(context, category),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap, required this.onDelete});

  final CategoryEntity category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // Same recipe as `ProductCard`/`_StatCard`: outer `Container` owns
    // shape/fill/shadow, transparent `Material`+`InkWell` inside just
    // supplies the ripple (see `_ProductTile` in admin_products_page.dart
    // for why the previous Material-outer/Container-inner layering rendered
    // as a flat gray block instead of a proper white card).
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(iconForCategory(category.iconKey), color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name, style: AppTextStyles.title),
                      if (category.subcategories.isNotEmpty)
                        Text(
                          'admin.subcategory_count'.tr(namedArgs: {'count': '${category.subcategories.length}'}),
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
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
      ),
    );
  }
}
