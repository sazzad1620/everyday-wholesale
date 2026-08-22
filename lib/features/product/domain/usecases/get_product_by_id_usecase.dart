import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

@injectable
class GetProductByIdUseCase extends UseCase<ProductEntity, String> {
  GetProductByIdUseCase(this._repository);

  final ProductRepository _repository;

  @override
  Future<Either<Failure, ProductEntity>> call(String id) => _repository.getProductById(id);
}
