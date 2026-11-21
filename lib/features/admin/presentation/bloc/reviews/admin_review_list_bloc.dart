import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/usecase/usecase.dart';
import '../../../../review/domain/usecases/delete_review_usecase.dart';
import '../../../../review/domain/usecases/get_all_reviews_usecase.dart';
import 'admin_review_list_event.dart';
import 'admin_review_list_state.dart';

@injectable
class AdminReviewListBloc extends Bloc<AdminReviewListEvent, AdminReviewListState> {
  AdminReviewListBloc(this._getAllReviewsUseCase, this._deleteReviewUseCase) : super(const AdminReviewListState()) {
    on<AdminReviewListRequested>(_onRequested);
    on<AdminReviewDeleteRequested>(_onDeleteRequested);
  }

  final GetAllReviewsUseCase _getAllReviewsUseCase;
  final DeleteReviewUseCase _deleteReviewUseCase;

  Future<void> _onRequested(AdminReviewListRequested event, Emitter<AdminReviewListState> emit) async {
    emit(const AdminReviewListState(isLoading: true));
    final result = await _getAllReviewsUseCase(const NoParams());
    result.match(
      (failure) => emit(AdminReviewListState(errorMessage: failure.messageKey)),
      (reviews) => emit(
        AdminReviewListState(reviews: [...reviews]..sort((a, b) => b.createdAt.compareTo(a.createdAt))),
      ),
    );
  }

  Future<void> _onDeleteRequested(AdminReviewDeleteRequested event, Emitter<AdminReviewListState> emit) async {
    emit(AdminReviewListState(reviews: state.reviews, isDeleting: true));
    final result = await _deleteReviewUseCase(
      DeleteReviewParams(reviewId: event.reviewId, productId: event.productId, rating: event.rating),
    );
    await result.match(
      (failure) async => emit(AdminReviewListState(reviews: state.reviews, errorMessage: failure.messageKey)),
      (_) async => _onRequested(const AdminReviewListRequested(), emit),
    );
  }
}
