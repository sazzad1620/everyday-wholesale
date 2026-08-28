import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_product_repository.dart';

@injectable
class DeleteProductUseCase extends UseCase<void, String> {
  DeleteProductUseCase(this._repository);

  final AdminProductRepository _repository;

  @override
  Future<Either<Failure, void>> call(String params) => _repository.deleteProduct(params);
}
