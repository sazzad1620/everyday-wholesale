import '../../../config/di/injection_container.dart';
import '../../../core/usecase/usecase.dart';
import '../../../features/home/domain/entities/category_entity.dart';
import '../../../features/home/domain/usecases/get_categories_usecase.dart';

/// Categories rarely change within a session, and every page needs the same
/// list for its [CategoryDrawer] (mobile) or [DesktopSidebar] (tablet/
/// desktop) — cached at module scope so it's fetched once per app session
/// instead of once per page that renders one of those.
Future<List<CategoryEntity>>? _cachedCategories;

Future<List<CategoryEntity>> cachedCategories() => _cachedCategories ??= _loadCategories();

Future<List<CategoryEntity>> _loadCategories() async {
  final result = await getIt<GetCategoriesUseCase>()(const NoParams());
  return result.match((_) => const [], (categories) => categories);
}
