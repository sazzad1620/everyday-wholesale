import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/category_entity.dart';

/// Shown for categories that have subcategories — lets the user either
/// browse everything in the category or drill into one subcategory.
/// Categories with no subcategories skip this and go straight to the
/// product list (see the Home category grid / drawer tap handlers).
class CategoryLandingPage extends StatelessWidget {
  const CategoryLandingPage({super.key, required this.category});

  final CategoryEntity category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(category.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _LandingTile(
            label: 'Browse All ${category.name}',
            highlighted: true,
            onTap: () => context.push(RoutePaths.categoryProducts(category.id), extra: category.name),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Shop by Subcategory', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          for (final sub in category.subcategories)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _LandingTile(
                label: sub.name,
                onTap: () => context.push(
                  RoutePaths.subcategoryProducts(category.id, sub.id),
                  extra: sub.name,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LandingTile extends StatelessWidget {
  const _LandingTile({required this.label, required this.onTap, this.highlighted = false});

  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          child: Row(
            children: [
              Icon(
                highlighted ? Icons.apps_rounded : Icons.label_outline_rounded,
                color: highlighted ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: highlighted ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: highlighted ? Colors.white : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
