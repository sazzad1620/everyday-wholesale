import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_category_repository.dart';

@injectable
class DeleteCategoryUseCase extends UseCase<void, String> {
  DeleteCategoryUseCase(this._repository);

  final AdminCategoryRepository _repository;

  @override
  Future<Either<Failure, void>> call(String params) => _repository.deleteCategory(params);
}
