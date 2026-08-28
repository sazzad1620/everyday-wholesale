import 'package:injectable/injectable.dart';

import '../../../../core/constants/asset_paths.dart';
import '../../domain/entities/promo_banner_entity.dart';

/// Promo banners are marketing content, not catalog data — no admin banner
/// management is planned yet, so these stay static rather than moving to
/// Firestore along with categories/products.
abstract class HomeLocalDatasource {
  Future<List<PromoBannerEntity>> getPromoBanners();
}

@LazySingleton(as: HomeLocalDatasource)
class HomeLocalDatasourceImpl implements HomeLocalDatasource {
  @override
  Future<List<PromoBannerEntity>> getPromoBanners() async {
    return const [PromoBannerEntity(id: 'main_banner', imagePath: AssetPaths.homeBanner)];
  }
}
