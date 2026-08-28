import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import '../datasources/admin_dashboard_remote_datasource.dart';

@LazySingleton(as: AdminDashboardRepository)
class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  AdminDashboardRepositoryImpl(this._datasource);

  final AdminDashboardRemoteDatasource _datasource;

  @override
  Future<Either<Failure, DashboardStatsEntity>> getDashboardStats() async {
    try {
      return Right(await _datasource.getDashboardStats());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
