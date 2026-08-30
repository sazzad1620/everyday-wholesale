import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/review_repository.dart';

@injectable
class SubmitReviewUseCase extends UseCase<void, SubmitReviewParams> {
  SubmitReviewUseCase(this._repository);

  final ReviewRepository _repository;

  @override
  Future<Either<Failure, void>> call(SubmitReviewParams params) => _repository.submitReview(
    orderId: params.orderId,
    productId: params.productId,
    productName: params.productName,
    productImageUrl: params.productImageUrl,
    reviewerName: params.reviewerName,
    rating: params.rating,
  );
}

class SubmitReviewParams extends Equatable {
  const SubmitReviewParams({
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.reviewerName,
    required this.rating,
    this.productImageUrl,
  });

  final String orderId;
  final String productId;
  final String productName;
  final String? productImageUrl;
  final String reviewerName;
  final int rating;

  @override
  List<Object?> get props => [orderId, productId, productName, productImageUrl, reviewerName, rating];
}
