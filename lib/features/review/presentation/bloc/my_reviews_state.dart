import 'package:equatable/equatable.dart';

import '../../domain/entities/review_entity.dart';
import '../../domain/entities/reviewable_item_entity.dart';

/// Single-class, flag-based state (matching [CategoryListState]) — backs
/// both My Reviews tabs at once, since To Be Reviewed and History are two
/// views over the same underlying fetch (completed orders + the customer's
/// existing reviews).
class MyReviewsState extends Equatable {
  const MyReviewsState({
    this.isLoading = false,
    this.reviewableItems = const [],
    this.historyReviews = const [],
    this.errorMessage,
    this.submittingKey,
  });

  final bool isLoading;
  final List<ReviewableItemEntity> reviewableItems;
  final List<ReviewEntity> historyReviews;
  final String? errorMessage;

  /// `"{orderId}_{productId}"` of the item currently being submitted, so
  /// only that one card shows a spinner — `null` when nothing is in flight.
  final String? submittingKey;

  @override
  List<Object?> get props => [isLoading, reviewableItems, historyReviews, errorMessage, submittingKey];
}
