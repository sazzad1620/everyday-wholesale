import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_dashboard_stats_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._getDashboardStatsUseCase) : super(const DashboardInitial()) {
    on<DashboardStatsRequested>(_onStatsRequested);
  }

  final GetDashboardStatsUseCase _getDashboardStatsUseCase;

  Future<void> _onStatsRequested(DashboardStatsRequested event, Emitter<DashboardState> emit) async {
    emit(const DashboardInProgress());
    final result = await _getDashboardStatsUseCase(const NoParams());
    result.match((failure) => emit(DashboardFailure(failure.message)), (stats) => emit(DashboardLoaded(stats)));
  }
}
