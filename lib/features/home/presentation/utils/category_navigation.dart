import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_paths.dart';
import '../../domain/entities/category_entity.dart';

/// Categories with no subcategories go straight to their product list;
/// categories with subcategories go to the "browse all or pick one" landing
/// page instead. Shared by the Home category grid and the category drawer
/// so both stay in sync.
void navigateToCategory(BuildContext context, CategoryEntity category) {
  if (category.subcategories.isEmpty) {
    context.push(RoutePaths.categoryProducts(category.id), extra: category.name);
  } else {
    context.push(RoutePaths.categoryBrowse(category.id), extra: category);
  }
}
