import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../repositories/admin_product_repository.dart';

@injectable
class UpdateProductUseCase extends UseCase<void, ProductEntity> {
  UpdateProductUseCase(this._repository);

  final AdminProductRepository _repository;

  @override
  Future<Either<Failure, void>> call(ProductEntity params) => _repository.updateProduct(params);
}
