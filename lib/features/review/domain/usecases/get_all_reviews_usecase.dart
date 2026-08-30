import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/review_entity.dart';
import '../repositories/review_repository.dart';

/// Admin-only — every review across every product/customer. Lives here
/// rather than under `admin/domain/usecases` since it's a plain read with no
/// admin-specific logic, same reasoning `GetCategoriesUseCase` is reused
/// as-is by the admin category list.
@injectable
class GetAllReviewsUseCase extends UseCase<List<ReviewEntity>, NoParams> {
  GetAllReviewsUseCase(this._repository);

  final ReviewRepository _repository;

  @override
  Future<Either<Failure, List<ReviewEntity>>> call(NoParams params) => _repository.getAllReviews();
}
