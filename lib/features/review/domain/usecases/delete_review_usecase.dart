import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/review_repository.dart';

/// Admin-only — Firestore rules reject this for anyone else. Lives here
/// rather than under `admin/domain/usecases`, same reasoning as
/// [GetAllReviewsUseCase].
@injectable
class DeleteReviewUseCase extends UseCase<void, DeleteReviewParams> {
  DeleteReviewUseCase(this._repository);

  final ReviewRepository _repository;

  @override
  Future<Either<Failure, void>> call(DeleteReviewParams params) => _repository.deleteReview(
    reviewId: params.reviewId,
    productId: params.productId,
    rating: params.rating,
  );
}

class DeleteReviewParams extends Equatable {
  const DeleteReviewParams({required this.reviewId, required this.productId, required this.rating});

  final String reviewId;
  final String productId;
  final int rating;

  @override
  List<Object?> get props => [reviewId, productId, rating];
}
