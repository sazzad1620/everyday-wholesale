import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

/// Every product the admin flagged Most Popular, across all categories.
@injectable
class GetMostPopularProductsUseCase extends UseCase<List<ProductEntity>, NoParams> {
  GetMostPopularProductsUseCase(this._repository);

  final ProductRepository _repository;

  @override
  Future<Either<Failure, List<ProductEntity>>> call(NoParams params) => _repository.getMostPopularProducts();
}
