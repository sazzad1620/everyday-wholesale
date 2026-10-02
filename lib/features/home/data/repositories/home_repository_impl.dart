import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/initial_home_data.dart';
import '../../domain/entities/promo_banner_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_initial_datasource.dart';
import '../datasources/home_remote_datasource.dart';

@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remoteDatasource, this._initialDatasource);

  final HomeRemoteDatasource _remoteDatasource;
  final HomeInitialDatasource _initialDatasource;

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      return Right(await _remoteDatasource.getCategories());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<PromoBannerEntity>>> getPromoBanners() async {
    try {
      return Right(await _remoteDatasource.getPromoBanners());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  InitialHomeData? initialHomeData() => _initialDatasource.read();

  @override
  Future<InitialHomeData?> cachedHomeData() => _initialDatasource.readCached();
}
