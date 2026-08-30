import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_datasource.dart';
import '../models/review_model.dart';

@LazySingleton(as: ReviewRepository)
class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._datasource, this._firebaseAuth);

  final ReviewRemoteDatasource _datasource;
  final FirebaseAuth _firebaseAuth;

  @override
  Future<Either<Failure, List<ReviewEntity>>> getMyReviews() async {
    try {
      return Right(await _datasource.getMyReviews());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<ReviewEntity>>> getProductReviews(String productId) async {
    try {
      return Right(await _datasource.getProductReviews(productId));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<ReviewEntity>>> getAllReviews() async {
    try {
      return Right(await _datasource.getAllReviews());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> submitReview({
    required String orderId,
    required String productId,
    required String productName,
    required String reviewerName,
    required int rating,
    String? productImageUrl,
  }) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return const Left(AuthFailure('Please sign in to submit a review.'));

    try {
      final review = ReviewModel(
        id: '',
        productId: productId,
        productName: productName,
        productImageUrl: productImageUrl,
        orderId: orderId,
        reviewerId: uid,
        reviewerName: reviewerName,
        rating: rating,
        createdAt: DateTime.now(),
      );
      await _datasource.submitReview(review);
      return const Right(null);
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
