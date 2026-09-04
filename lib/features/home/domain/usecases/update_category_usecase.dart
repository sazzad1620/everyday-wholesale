import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/admin_category_repository.dart';

@injectable
class UpdateCategoryUseCase extends UseCase<void, CategoryEntity> {
  UpdateCategoryUseCase(this._repository);

  final AdminCategoryRepository _repository;

  @override
  Future<Either<Failure, void>> call(CategoryEntity params) => _repository.updateCategory(params);
}
