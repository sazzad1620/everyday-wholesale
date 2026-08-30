import 'package:equatable/equatable.dart';

/// A single 1–5 star rating a customer left for a product, tied to the
/// specific completed order that made them eligible to review it. Doc id is
/// `{orderId}_{productId}` (see `ReviewRemoteDatasource.submitReview`), so a
/// given order+product pair can only ever produce one review.
class ReviewEntity extends Equatable {
  const ReviewEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.orderId,
    required this.reviewerId,
    required this.reviewerName,
    required this.rating,
    required this.createdAt,
    this.productImageUrl,
  });

  final String id;
  final String productId;
  final String productName;
  final String? productImageUrl;
  final String orderId;
  final String reviewerId;
  final String reviewerName;

  /// Whole stars, 1–5 — only the product's aggregate ([ProductEntity.rating])
  /// can land on a half-star value, never an individual review.
  final int rating;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    productImageUrl,
    orderId,
    reviewerId,
    reviewerName,
    rating,
    createdAt,
  ];
}
