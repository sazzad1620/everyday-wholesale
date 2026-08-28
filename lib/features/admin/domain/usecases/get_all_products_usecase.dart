import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../repositories/admin_product_repository.dart';

@injectable
class GetAllProductsUseCase extends UseCase<List<ProductEntity>, NoParams> {
  GetAllProductsUseCase(this._repository);

  final AdminProductRepository _repository;

  @override
  Future<Either<Failure, List<ProductEntity>>> call(NoParams params) => _repository.getAllProducts();
}
