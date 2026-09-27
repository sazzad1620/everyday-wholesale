import 'package:equatable/equatable.dart';

import '../../../product/domain/entities/product_entity.dart';
import 'category_entity.dart';
import 'promo_banner_entity.dart';

/// Home-page data the web server embedded in the page it served (see the
/// `ssr` Cloud Function), available before any Firestore request. Only ever
/// a starting point — the app still refreshes it from Firestore.
class InitialHomeData extends Equatable {
  const InitialHomeData({required this.categories, required this.banners, required this.popular});

  /// Real categories only (the virtual Most Popular one is derived).
  final List<CategoryEntity> categories;
  final List<PromoBannerEntity> banners;
  final List<ProductEntity> popular;

  @override
  List<Object?> get props => [categories, banners, popular];
}
