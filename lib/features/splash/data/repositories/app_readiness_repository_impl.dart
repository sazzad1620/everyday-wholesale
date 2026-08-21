import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/app_readiness_repository.dart';
import '../datasources/app_readiness_local_datasource.dart';

@LazySingleton(as: AppReadinessRepository)
class AppReadinessRepositoryImpl implements AppReadinessRepository {
  AppReadinessRepositoryImpl(this._localDatasource);

  final AppReadinessLocalDatasource _localDatasource;

  @override
  Future<Either<Failure, bool>> checkAppReady() async {
    try {
      final isReady = await _localDatasource.checkAppReady();
      return Right(isReady);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
