import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/update_order_status_usecase.dart';
import 'admin_order_detail_event.dart';
import 'admin_order_detail_state.dart';

/// One per detail-page visit (`@injectable`, not shared) — mirrors
/// [CategoryFormBloc].
@injectable
class AdminOrderDetailBloc extends Bloc<AdminOrderDetailEvent, AdminOrderDetailState> {
  AdminOrderDetailBloc(this._updateOrderStatusUseCase) : super(const AdminOrderDetailState()) {
    on<AdminOrderDetailStatusChangeRequested>(_onStatusChangeRequested);
  }

  final UpdateOrderStatusUseCase _updateOrderStatusUseCase;

  Future<void> _onStatusChangeRequested(
    AdminOrderDetailStatusChangeRequested event,
    Emitter<AdminOrderDetailState> emit,
  ) async {
    emit(const AdminOrderDetailState(isUpdating: true));
    final result = await _updateOrderStatusUseCase(
      UpdateOrderStatusParams(orderId: event.orderId, status: event.status),
    );
    result.match(
      (failure) => emit(AdminOrderDetailState(errorMessage: failure.message)),
      (_) => emit(const AdminOrderDetailState(success: true)),
    );
  }
}
