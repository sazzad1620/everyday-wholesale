import 'package:equatable/equatable.dart';

import '../../../domain/entities/dashboard_stats_entity.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardInProgress extends DashboardState {
  const DashboardInProgress();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded(this.stats);

  final DashboardStatsEntity stats;

  @override
  List<Object?> get props => [stats];
}

class DashboardFailure extends DashboardState {
  const DashboardFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
