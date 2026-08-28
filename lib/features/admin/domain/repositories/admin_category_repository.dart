import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../home/domain/entities/category_entity.dart';

/// Write-side counterpart to [HomeRepository]'s read-only `getCategories` —
/// kept separate (Interface Segregation) since only the admin side ever
/// mutates categories. Category reads still go through the existing
/// `GetCategoriesUseCase` (home feature), reused as-is for the admin list.
abstract class AdminCategoryRepository {
  Future<Either<Failure, void>> createCategory(CategoryEntity category);

  Future<Either<Failure, void>> updateCategory(CategoryEntity category);

  Future<Either<Failure, void>> deleteCategory(String categoryId);
}
