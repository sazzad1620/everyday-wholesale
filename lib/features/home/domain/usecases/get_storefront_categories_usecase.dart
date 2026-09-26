import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../product/domain/repositories/product_repository.dart';
import '../entities/category_entity.dart';
import '../entities/most_popular_category.dart';
import '../repositories/home_repository.dart';

/// The customer-facing category list (sidebar, drawer, breadcrumbs): the
/// real categories, led by the virtual Most Popular one whenever at least
/// one product is flagged. Admin screens keep using [GetCategoriesUseCase],
/// which never includes it.
@injectable
class GetStorefrontCategoriesUseCase extends UseCase<List<CategoryEntity>, NoParams> {
  GetStorefrontCategoriesUseCase(this._homeRepository, this._productRepository);

  final HomeRepository _homeRepository;
  final ProductRepository _productRepository;

  @override
  Future<Either<Failure, List<CategoryEntity>>> call(NoParams params) async {
    final categoriesResult = await _homeRepository.getCategories();
    // A failed Most Popular lookup just hides that entry — it shouldn't take
    // the whole category list down with it.
    final popularResult = await _productRepository.getMostPopularProducts();
    final hasMostPopular = popularResult.match((_) => false, (products) => products.isNotEmpty);
    return categoriesResult.map((categories) => withMostPopular(categories, hasMostPopular: hasMostPopular));
  }
}
