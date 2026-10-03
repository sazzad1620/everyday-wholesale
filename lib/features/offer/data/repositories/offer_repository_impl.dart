import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/offer_entity.dart';
import '../../domain/repositories/offer_repository.dart';
import '../datasources/offer_local_datasource.dart';
import '../datasources/offer_remote_datasource.dart';
import '../models/offer_model.dart';

@LazySingleton(as: OfferRepository)
class OfferRepositoryImpl implements OfferRepository {
  OfferRepositoryImpl(this._datasource, this._local);

  final OfferRemoteDatasource _datasource;
  final OfferLocalDatasource _local;

  @override
  Future<Either<Failure, List<OfferEntity>>> getOffers({required bool includeExpired}) async {
    try {
      return Right(await _datasource.getOffers(includeExpired: includeExpired));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> createOffer(OfferEntity offer) async {
    try {
      await _datasource.createOffer(OfferModel.fromEntity(offer));
      return const Right(null);
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> hasUnseenOffers() async {
    try {
      final latest = await _datasource.getLatestOfferTime();
      if (latest == null) return const Right(false);
      final lastSeen = await _local.getLastSeen();
      return Right(lastSeen == null || latest.isAfter(lastSeen));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markOffersSeen() async {
    try {
      final latest = await _datasource.getLatestOfferTime();
      if (latest != null) await _local.setLastSeen(latest);
      return const Right(null);
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteOffer(String id) async {
    try {
      await _datasource.deleteOffer(id);
      return const Right(null);
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
