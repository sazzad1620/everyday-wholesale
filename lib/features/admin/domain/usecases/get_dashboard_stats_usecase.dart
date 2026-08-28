import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/dashboard_stats_entity.dart';
import '../repositories/admin_dashboard_repository.dart';

@injectable
class GetDashboardStatsUseCase extends UseCase<DashboardStatsEntity, NoParams> {
  GetDashboardStatsUseCase(this._repository);

  final AdminDashboardRepository _repository;

  @override
  Future<Either<Failure, DashboardStatsEntity>> call(NoParams params) => _repository.getDashboardStats();
}
