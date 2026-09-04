import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/usecase/usecase.dart';
import '../../../../review/domain/usecases/get_all_reviews_usecase.dart';
import 'admin_review_list_event.dart';
import 'admin_review_list_state.dart';

@injectable
class AdminReviewListBloc extends Bloc<AdminReviewListEvent, AdminReviewListState> {
  AdminReviewListBloc(this._getAllReviewsUseCase) : super(const AdminReviewListState()) {
    on<AdminReviewListRequested>(_onRequested);
  }

  final GetAllReviewsUseCase _getAllReviewsUseCase;

  Future<void> _onRequested(AdminReviewListRequested event, Emitter<AdminReviewListState> emit) async {
    emit(const AdminReviewListState(isLoading: true));
    final result = await _getAllReviewsUseCase(const NoParams());
    result.match(
      (failure) => emit(AdminReviewListState(errorMessage: failure.message)),
      (reviews) => emit(
        AdminReviewListState(reviews: [...reviews]..sort((a, b) => b.createdAt.compareTo(a.createdAt))),
      ),
    );
  }
}
