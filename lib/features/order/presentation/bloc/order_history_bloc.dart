import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_order_history_usecase.dart';
import 'order_history_event.dart';
import 'order_history_state.dart';

@injectable
class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  OrderHistoryBloc(this._getOrderHistoryUseCase) : super(const OrderHistoryInitial()) {
    on<OrderHistoryRequested>(_onRequested);
  }

  final GetOrderHistoryUseCase _getOrderHistoryUseCase;

  Future<void> _onRequested(OrderHistoryRequested event, Emitter<OrderHistoryState> emit) async {
    emit(const OrderHistoryInProgress());
    final result = await _getOrderHistoryUseCase(const NoParams());
    result.match(
      (failure) => emit(OrderHistoryFailure(failure.message)),
      (orders) => emit(OrderHistoryLoaded(orders)),
    );
  }
}
