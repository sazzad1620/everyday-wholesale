import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

@injectable
class SearchProductsUseCase extends UseCase<List<ProductEntity>, String> {
  SearchProductsUseCase(this._repository);

  final ProductRepository _repository;

  @override
  Future<Either<Failure, List<ProductEntity>>> call(String params) => _repository.searchProducts(params);
}
