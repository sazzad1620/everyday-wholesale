import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/review_entity.dart';
import '../repositories/review_repository.dart';

@injectable
class GetProductReviewsUseCase extends UseCase<List<ReviewEntity>, String> {
  GetProductReviewsUseCase(this._repository);

  final ReviewRepository _repository;

  @override
  Future<Either<Failure, List<ReviewEntity>>> call(String params) => _repository.getProductReviews(params);
}
