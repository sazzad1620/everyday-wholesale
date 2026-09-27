import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/category_entity.dart';
import '../entities/initial_home_data.dart';
import '../entities/promo_banner_entity.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories();

  Future<Either<Failure, List<PromoBannerEntity>>> getPromoBanners();

  /// Home data embedded by the web server in the page it served, if any.
  InitialHomeData? initialHomeData();
}
