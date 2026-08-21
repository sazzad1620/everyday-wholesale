import 'package:injectable/injectable.dart';

import '../../../../core/constants/asset_paths.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/promo_banner_entity.dart';
import '../../domain/entities/subcategory_entity.dart';

/// Stands in for a Firestore-backed datasource until the Firebase
/// integration phase. The repository/usecase/bloc layers above it are
/// already written against the final contract, so swapping this out later
/// only touches this file.
abstract class HomeMockDatasource {
  Future<List<CategoryEntity>> getCategories();

  Future<List<PromoBannerEntity>> getPromoBanners();
}

@LazySingleton(as: HomeMockDatasource)
class HomeMockDatasourceImpl implements HomeMockDatasource {
  @override
  Future<List<CategoryEntity>> getCategories() async {
    return const [
      CategoryEntity(
        id: 'most_popular',
        name: 'Most Popular',
        iconKey: 'most_popular',
        imageUrl: AssetPaths.demoCategoryImageMostPopular,
      ),
      CategoryEntity(
        id: 'meat_fish',
        name: 'Meat & Fish',
        iconKey: 'meat_fish',
        imageUrl: AssetPaths.demoCategoryImageMeatFish,
        subcategories: [
          SubcategoryEntity(id: 'beef', name: 'Beef'),
          SubcategoryEntity(id: 'mutton', name: 'Mutton'),
          SubcategoryEntity(id: 'chicken', name: 'Chicken'),
          SubcategoryEntity(id: 'fish_seafood', name: 'Fish & Seafood'),
        ],
      ),
      CategoryEntity(id: 'fruits_vegetables', name: 'Fruits & Vegetables', iconKey: 'fruits_vegetables'),
      CategoryEntity(
        id: 'frozen_food',
        name: 'Frozen Food',
        iconKey: 'frozen_food',
        subcategories: [
          SubcategoryEntity(id: 'frozen_snacks', name: 'Frozen Snacks'),
          SubcategoryEntity(id: 'frozen_vegetables', name: 'Frozen Vegetables'),
          SubcategoryEntity(id: 'frozen_meat', name: 'Frozen Meat'),
        ],
      ),
      CategoryEntity(id: 'beverages', name: 'Beverages', iconKey: 'beverages'),
      CategoryEntity(
        id: 'masala_spice',
        name: 'Masala & Spice',
        iconKey: 'masala_spice',
        subcategories: [
          SubcategoryEntity(id: 'whole_spices', name: 'Whole Spices'),
          SubcategoryEntity(id: 'masala_mixes', name: 'Masala Mixes'),
          SubcategoryEntity(id: 'cooking_paste', name: 'Cooking Paste'),
        ],
      ),
      CategoryEntity(id: 'halal_products', name: 'Halal Products', iconKey: 'halal_products'),
      CategoryEntity(id: 'rice_grains', name: 'Rice & Grains', iconKey: 'rice_grains'),
    ];
  }

  @override
  Future<List<PromoBannerEntity>> getPromoBanners() async {
    return const [
      PromoBannerEntity(id: 'main_banner', imagePath: AssetPaths.homeBanner),
    ];
  }
}
