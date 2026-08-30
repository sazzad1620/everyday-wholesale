import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/review_model.dart';

abstract class ReviewRemoteDatasource {
  Future<List<ReviewModel>> getMyReviews();

  Future<List<ReviewModel>> getProductReviews(String productId);

  Future<List<ReviewModel>> getAllReviews();

  Future<void> submitReview(ReviewModel review);
}

@LazySingleton(as: ReviewRemoteDatasource)
class ReviewRemoteDatasourceImpl implements ReviewRemoteDatasource {
  ReviewRemoteDatasourceImpl(this._firestore, this._firebaseAuth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  static const _reviewsCollection = 'reviews';
  static const _productsCollection = 'products';

  @override
  Future<List<ReviewModel>> getMyReviews() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw const AuthException('Please sign in to view your reviews.');
    // Sorted client-side, matching `OrderRemoteDatasourceImpl` — no composite
    // index needed for a single-field equality filter.
    final snapshot = await _firestore.collection(_reviewsCollection).where('reviewerId', isEqualTo: uid).get();
    return snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data(), id: doc.id)).toList();
  }

  @override
  Future<List<ReviewModel>> getProductReviews(String productId) async {
    final snapshot = await _firestore
        .collection(_reviewsCollection)
        .where('productId', isEqualTo: productId)
        .get();
    return snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data(), id: doc.id)).toList();
  }

  @override
  Future<List<ReviewModel>> getAllReviews() async {
    final snapshot = await _firestore.collection(_reviewsCollection).get();
    return snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data(), id: doc.id)).toList();
  }

  @override
  Future<void> submitReview(ReviewModel review) async {
    // Deterministic id — one order+product pair can only ever produce one
    // review doc, enforced both here and by Firestore rules (`allow update:
    // if false` means a resubmission just fails outright).
    final reviewId = '${review.orderId}_${review.productId}';
    final batch = _firestore.batch();
    batch.set(_firestore.collection(_reviewsCollection).doc(reviewId), {
      ...review.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Pure increments — no need to read the product first, so a batch
    // (not a transaction) is enough to keep both writes atomic.
    batch.update(_firestore.collection(_productsCollection).doc(review.productId), {
      'ratingSum': FieldValue.increment(review.rating),
      'reviewCount': FieldValue.increment(1),
    });
    await batch.commit();
  }
}
