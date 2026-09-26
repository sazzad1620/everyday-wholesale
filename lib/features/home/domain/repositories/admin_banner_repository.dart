import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/promo_banner_entity.dart';

/// Write-side counterpart to [HomeRepository]'s `getPromoBanners` — same
/// split as [AdminCategoryRepository]. The admin list reuses
/// `GetPromoBannersUseCase` for reads.
abstract class AdminBannerRepository {
  Future<Either<Failure, void>> addBanner(Uint8List bytes, String fileExtension, int order);

  Future<Either<Failure, void>> deleteBanner(PromoBannerEntity banner);

  Future<Either<Failure, void>> reorderBanners(List<PromoBannerEntity> banners);
}
