import '../../../config/di/injection_container.dart';
import '../../../core/usecase/usecase.dart';
import '../../../features/home/domain/entities/category_entity.dart';
import '../../../features/home/domain/entities/most_popular_category.dart';
import '../../../features/home/domain/usecases/get_initial_home_data_usecase.dart';
import '../../../features/home/domain/usecases/get_storefront_categories_usecase.dart';

/// Categories rarely change within a session, and every page needs the same
/// list for its [CategoryDrawer] (mobile) or [DesktopSidebar] (tablet/
/// desktop) — cached at module scope so it's fetched once per app session
/// instead of once per page that renders one of those.
Future<List<CategoryEntity>>? _cachedCategories;

Future<List<CategoryEntity>> cachedCategories() => _cachedCategories ??= _loadCategories();

Future<List<CategoryEntity>> _loadCategories() async {
  // A server-rendered home page already carries the category list — use it
  // so the sidebar paints on the first frame instead of after a Firestore
  // round trip. (Same once-per-session freshness as the Firestore path.)
  final initial = getIt<GetInitialHomeDataUseCase>()();
  if (initial != null) {
    return withMostPopular(initial.categories, hasMostPopular: initial.popular.isNotEmpty);
  }
  final result = await getIt<GetStorefrontCategoriesUseCase>()(const NoParams());
  return result.match((_) => const [], (categories) => categories);
}
