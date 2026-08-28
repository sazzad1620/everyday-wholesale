import '../../domain/entities/product_review_entity.dart';

class ProductReviewModel extends ProductReviewEntity {
  const ProductReviewModel({required super.reviewerName, required super.rating, required super.comment});

  factory ProductReviewModel.fromMap(Map<String, dynamic> map) {
    return ProductReviewModel(
      reviewerName: map['reviewerName'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      comment: map['comment'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'reviewerName': reviewerName, 'rating': rating, 'comment': comment};
}
