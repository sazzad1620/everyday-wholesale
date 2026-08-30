import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/review_entity.dart';

/// Mirrors a `reviews/{reviewId}` Firestore document. `id` is the document
/// ID (`{orderId}_{productId}`), not a stored field.
class ReviewModel extends ReviewEntity {
  const ReviewModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.orderId,
    required super.reviewerId,
    required super.reviewerName,
    required super.rating,
    required super.createdAt,
    super.productImageUrl,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, {required String id}) {
    final createdAtValue = map['createdAt'];
    return ReviewModel(
      id: id,
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      productImageUrl: map['productImageUrl'] as String?,
      orderId: map['orderId'] as String? ?? '',
      reviewerId: map['reviewerId'] as String? ?? '',
      reviewerName: map['reviewerName'] as String? ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      // Only null immediately after a fresh write, before the server has
      // resolved `FieldValue.serverTimestamp()` on a subsequent read — same
      // fallback `OrderModel.fromMap` uses.
      createdAt: createdAtValue is Timestamp ? createdAtValue.toDate() : DateTime.now(),
    );
  }

  /// `createdAt` deliberately isn't included — set via
  /// `FieldValue.serverTimestamp()` at write time in the datasource instead.
  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'productImageUrl': productImageUrl,
    'orderId': orderId,
    'reviewerId': reviewerId,
    'reviewerName': reviewerName,
    'rating': rating,
  };
}
