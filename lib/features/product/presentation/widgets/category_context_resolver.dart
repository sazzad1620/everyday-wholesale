import 'package:flutter/widgets.dart';

import '../../../../core/localization/localized_text.dart';
import '../../../../shared/widgets/navigation/categories_cache.dart';
import '../../../home/domain/entities/category_entity.dart';
import '../../../home/domain/entities/subcategory_entity.dart';

/// Everything the product list / detail pages need about the category they
/// sit under, beyond the ids that are in the URL.
typedef CategoryContext = ({
  LocalizedText categoryName,
  LocalizedText? subcategoryName,
  List<SubcategoryEntity> subcategories,
});

/// Supplies a [CategoryContext] to [builder], from the route's `extra` when
/// the page was reached by an in-app tap, and otherwise from the session's
/// category cache — a deep link, a browser refresh, or the language
/// switcher's tree remount all re-parse the URL, which carries only ids.
/// Without this those cases showed the raw id in the breadcrumb and lost the
/// subcategory grid.
class CategoryContextResolver extends StatelessWidget {
  const CategoryContextResolver({
    super.key,
    required this.categoryId,
    this.subcategoryId,
    this.categoryName,
    this.subcategoryName,
    this.subcategories = const [],
    required this.builder,
  });

  final String categoryId;
  final String? subcategoryId;

  /// From the route `extra`; `null` means "look it up".
  final LocalizedText? categoryName;
  final LocalizedText? subcategoryName;
  final List<SubcategoryEntity> subcategories;
  final Widget Function(BuildContext context, CategoryContext ctx) builder;

  @override
  Widget build(BuildContext context) {
    if (categoryName != null) {
      return builder(context, (
        categoryName: categoryName!,
        subcategoryName: subcategoryName,
        subcategories: subcategories,
      ));
    }
    return FutureBuilder<List<CategoryEntity>>(
      future: cachedCategories(),
      builder: (context, snapshot) => builder(context, _fromCategories(snapshot.data)),
    );
  }

  /// Ids stand in for the names until (or if) the cache answers, so the
  /// page still renders something meaningful for an unknown id.
  CategoryContext _fromCategories(List<CategoryEntity>? categories) {
    CategoryEntity? category;
    for (final c in categories ?? const <CategoryEntity>[]) {
      if (c.id == categoryId) category = c;
    }
    SubcategoryEntity? subcategory;
    for (final s in category?.subcategories ?? const <SubcategoryEntity>[]) {
      if (s.id == subcategoryId) subcategory = s;
    }
    return (
      categoryName: category?.name ?? LocalizedText(en: categoryId),
      subcategoryName: subcategory?.name ?? (subcategoryId == null ? null : LocalizedText(en: subcategoryId!)),
      subcategories: category?.subcategories ?? subcategories,
    );
  }
}
