import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/home_repository.dart';

@injectable
class GetCategoriesUseCase extends UseCase<List<CategoryEntity>, NoParams> {
  GetCategoriesUseCase(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, List<CategoryEntity>>> call(NoParams params) {
    return _repository.getCategories();
  }
}
