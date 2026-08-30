import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/review_entity.dart';

abstract class ReviewRepository {
  /// Every review the signed-in customer has submitted, newest first.
  Future<Either<Failure, List<ReviewEntity>>> getMyReviews();

  /// Every review submitted for one product — shown on that product's own
  /// detail page.
  Future<Either<Failure, List<ReviewEntity>>> getProductReviews(String productId);

  /// Every review across every product/customer — admin-only listing.
  Future<Either<Failure, List<ReviewEntity>>> getAllReviews();

  Future<Either<Failure, void>> submitReview({
    required String orderId,
    required String productId,
    required String productName,
    required String reviewerName,
    required int rating,
    String? productImageUrl,
  });
}
