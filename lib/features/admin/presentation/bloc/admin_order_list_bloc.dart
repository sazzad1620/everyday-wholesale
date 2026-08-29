import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_all_orders_usecase.dart';
import '../../domain/usecases/update_order_status_usecase.dart';
import 'admin_order_list_event.dart';
import 'admin_order_list_state.dart';

@injectable
class AdminOrderListBloc extends Bloc<AdminOrderListEvent, AdminOrderListState> {
  AdminOrderListBloc(this._getAllOrdersUseCase, this._updateOrderStatusUseCase) : super(const AdminOrderListState()) {
    on<AdminOrderListRequested>(_onRequested);
    on<AdminOrderStatusUpdateRequested>(_onStatusUpdateRequested);
  }

  final GetAllOrdersUseCase _getAllOrdersUseCase;
  final UpdateOrderStatusUseCase _updateOrderStatusUseCase;

  Future<void> _onRequested(AdminOrderListRequested event, Emitter<AdminOrderListState> emit) async {
    emit(const AdminOrderListState(isLoading: true));
    final result = await _getAllOrdersUseCase(const NoParams());
    result.match(
      (failure) => emit(AdminOrderListState(errorMessage: failure.message)),
      (orders) => emit(AdminOrderListState(orders: orders)),
    );
  }

  Future<void> _onStatusUpdateRequested(
    AdminOrderStatusUpdateRequested event,
    Emitter<AdminOrderListState> emit,
  ) async {
    emit(AdminOrderListState(orders: state.orders, isUpdating: true));
    final result = await _updateOrderStatusUseCase(
      UpdateOrderStatusParams(orderId: event.orderId, status: event.status),
    );
    await result.match(
      (failure) async => emit(AdminOrderListState(orders: state.orders, errorMessage: failure.message)),
      (_) async => _onRequested(const AdminOrderListRequested(), emit),
    );
  }
}
