import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/promo_banner_entity.dart';
import '../../domain/repositories/admin_banner_repository.dart';
import '../datasources/admin_banner_remote_datasource.dart';
import '../models/promo_banner_model.dart';

@LazySingleton(as: AdminBannerRepository)
class AdminBannerRepositoryImpl implements AdminBannerRepository {
  AdminBannerRepositoryImpl(this._datasource);

  final AdminBannerRemoteDatasource _datasource;

  @override
  Future<Either<Failure, void>> addBanner(Uint8List bytes, String fileExtension, int order) async {
    try {
      await _datasource.createBanner(bytes, fileExtension, order);
      return const Right(null);
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteBanner(PromoBannerEntity banner) async {
    try {
      await _datasource.deleteBanner(_toModel(banner));
      return const Right(null);
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> reorderBanners(List<PromoBannerEntity> banners) async {
    try {
      await _datasource.reorderBanners(banners.map(_toModel).toList());
      return const Right(null);
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  PromoBannerModel _toModel(PromoBannerEntity banner) => PromoBannerModel(
    id: banner.id,
    imageUrl: banner.imageUrl,
    storagePath: banner.storagePath,
    order: banner.order,
  );
}
