import 'package:equatable/equatable.dart';

import '../../../review/domain/entities/review_entity.dart';

class AdminReviewListState extends Equatable {
  const AdminReviewListState({this.isLoading = false, this.reviews = const [], this.errorMessage});

  final bool isLoading;
  final List<ReviewEntity> reviews;
  final String? errorMessage;

  @override
  List<Object?> get props => [isLoading, reviews, errorMessage];
}
