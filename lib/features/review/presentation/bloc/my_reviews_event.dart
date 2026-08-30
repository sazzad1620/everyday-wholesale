import 'package:equatable/equatable.dart';

abstract class MyReviewsEvent extends Equatable {
  const MyReviewsEvent();

  @override
  List<Object?> get props => [];
}

class MyReviewsRequested extends MyReviewsEvent {
  const MyReviewsRequested();
}

class MyReviewsSubmitRequested extends MyReviewsEvent {
  const MyReviewsSubmitRequested({
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
