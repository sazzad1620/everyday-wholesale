import 'package:equatable/equatable.dart';

import '../../../../review/domain/entities/review_entity.dart';

class AdminReviewListState extends Equatable {
  const AdminReviewListState({
    this.isLoading = false,
    this.reviews = const [],
    this.errorMessage,
    this.isDeleting = false,
  });

  final bool isLoading;
  final List<ReviewEntity> reviews;
  final String? errorMessage;

  /// Keeps the current list on screen during a delete, instead of blanking
  /// to a loading state — same reasoning as [AdminProductListState].
  final bool isDeleting;

  @override
  List<Object?> get props => [isLoading, reviews, errorMessage, isDeleting];
}
