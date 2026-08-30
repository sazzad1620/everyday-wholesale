import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/domain/entities/order_status.dart';
import '../../../order/domain/usecases/get_order_history_usecase.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/entities/reviewable_item_entity.dart';
import '../../domain/usecases/get_my_reviews_usecase.dart';
import '../../domain/usecases/submit_review_usecase.dart';
import 'my_reviews_event.dart';
import 'my_reviews_state.dart';

@injectable
class MyReviewsBloc extends Bloc<MyReviewsEvent, MyReviewsState> {
  MyReviewsBloc(this._getOrderHistoryUseCase, this._getMyReviewsUseCase, this._submitReviewUseCase)
    : super(const MyReviewsState()) {
    on<MyReviewsRequested>(_onRequested);
    on<MyReviewsSubmitRequested>(_onSubmitRequested);
  }

  final GetOrderHistoryUseCase _getOrderHistoryUseCase;
  final GetMyReviewsUseCase _getMyReviewsUseCase;
  final SubmitReviewUseCase _submitReviewUseCase;

  Future<void> _onRequested(MyReviewsRequested event, Emitter<MyReviewsState> emit) async {
    emit(const MyReviewsState(isLoading: true));
    await _fetchAndEmit(emit);
  }

  Future<void> _onSubmitRequested(MyReviewsSubmitRequested event, Emitter<MyReviewsState> emit) async {
    final key = '${event.orderId}_${event.productId}';
    emit(
      MyReviewsState(
        reviewableItems: state.reviewableItems,
        historyReviews: state.historyReviews,
        submittingKey: key,
      ),
    );

    final result = await _submitReviewUseCase(
      SubmitReviewParams(
        orderId: event.orderId,
        productId: event.productId,
        productName: event.productName,
        productImageUrl: event.productImageUrl,
        reviewerName: event.reviewerName,
        rating: event.rating,
      ),
    );

    await result.match(
      (failure) async => emit(
        MyReviewsState(
          reviewableItems: state.reviewableItems,
          historyReviews: state.historyReviews,
          errorMessage: failure.message,
        ),
      ),
      (_) async => _fetchAndEmit(emit),
    );
  }

  Future<void> _fetchAndEmit(Emitter<MyReviewsState> emit) async {
    final ordersResult = await _getOrderHistoryUseCase(const NoParams());
    final reviewsResult = await _getMyReviewsUseCase(const NoParams());

    final orders = ordersResult.match((_) => const <OrderEntity>[], (value) => value);
    final reviews = reviewsResult.match((_) => const <ReviewEntity>[], (value) => value).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final reviewedKeys = reviews.map((review) => '${review.orderId}_${review.productId}').toSet();
    final reviewableItems = [
      for (final order in orders)
        if (order.status == OrderStatus.completed)
          for (final item in order.items)
            if (!reviewedKeys.contains('${order.id}_${item.productId}'))
              ReviewableItemEntity(
                orderId: order.id,
                productId: item.productId,
                productName: item.name,
                productImageUrl: item.imageUrl,
                orderDate: order.createdAt,
              ),
    ];

    emit(MyReviewsState(reviewableItems: reviewableItems, historyReviews: reviews));
  }
}
