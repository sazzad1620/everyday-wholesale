import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_paths.dart';
import '../../domain/entities/category_entity.dart';

/// Every category goes to the same product-list page, whether or not it has
/// subcategories — when it does, that page shows them as a card grid above
/// the product grid instead of a separate landing page. Shared by the Home
/// category grid and the category drawer so both stay in sync.
void navigateToCategory(BuildContext context, CategoryEntity category) {
  context.push(
    RoutePaths.categoryProducts(category.id),
    extra: (categoryName: category.name, subcategories: category.subcategories),
  );
}
