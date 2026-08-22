import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/route_paths.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class BreadcrumbItem {
  const BreadcrumbItem({required this.label, required this.onTap, this.isCurrent = false});

  final String label;
  final VoidCallback onTap;
  final bool isCurrent;
}

/// Home icon, then one item per level (category, optionally subcategory).
/// Every segment is tappable; the deepest one (where the user currently is)
/// renders semi-bold instead of navigating anywhere new.
class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({super.key, required this.items});

  final List<BreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go(RoutePaths.home),
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.home_rounded, size: 18, color: AppColors.textSecondary),
            ),
          ),
          for (final item in items) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
            ),
            Flexible(
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: item.isCurrent ? FontWeight.w700 : FontWeight.w400,
                      color: item.isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
