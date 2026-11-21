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

/// Same source as [cachedCategories], but synchronous — available the
/// instant a server-rendered page carries its category list, with no
/// `FutureBuilder` gap. `null` off a server-rendered page (an in-app
/// navigation, or mobile), where there's nothing to read synchronously and
/// callers fall back to [cachedCategories] instead.
///
/// [GetInitialHomeDataUseCase] parses its embedded JSON once and caches the
/// result on the (singleton) datasource itself, so calling it again here —
/// on top of [_loadCategories]'s own call — is free, not a second parse.
List<CategoryEntity>? initialCategoriesSync() {
  final initial = getIt<GetInitialHomeDataUseCase>()();
  if (initial == null) return null;
  return withMostPopular(initial.categories, hasMostPopular: initial.popular.isNotEmpty);
}

Future<List<CategoryEntity>> _loadCategories() async {
  // A server-rendered home page already carries the category list — use it
  // so the sidebar paints on the first frame instead of after a Firestore
  // round trip. (Same once-per-session freshness as the Firestore path.)
  final initial = initialCategoriesSync();
  if (initial != null) return initial;
  final result = await getIt<GetStorefrontCategoriesUseCase>()(const NoParams());
  return result.match((_) => const [], (categories) => categories);
}
