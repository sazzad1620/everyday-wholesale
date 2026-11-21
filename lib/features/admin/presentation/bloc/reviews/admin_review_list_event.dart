import 'package:equatable/equatable.dart';

abstract class AdminReviewListEvent extends Equatable {
  const AdminReviewListEvent();

  @override
  List<Object?> get props => [];
}

class AdminReviewListRequested extends AdminReviewListEvent {
  const AdminReviewListRequested();
}

class AdminReviewDeleteRequested extends AdminReviewListEvent {
  const AdminReviewDeleteRequested({required this.reviewId, required this.productId, required this.rating});

  final String reviewId;
  final String productId;
  final int rating;

  @override
  List<Object?> get props => [reviewId, productId, rating];
}
