import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_stats_entity.dart';

abstract class AdminDashboardRepository {
  Future<Either<Failure, DashboardStatsEntity>> getDashboardStats();
}
