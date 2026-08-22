import 'package:equatable/equatable.dart';

class ProductReviewEntity extends Equatable {
  const ProductReviewEntity({required this.reviewerName, required this.rating, required this.comment});

  final String reviewerName;

  /// 0.0–5.0.
  final double rating;
  final String comment;

  @override
  List<Object?> get props => [reviewerName, rating, comment];
}
