import 'package:injectable/injectable.dart';

import '../../../../core/constants/asset_paths.dart';
import '../../domain/entities/product_entity.dart';

abstract class ProductMockDatasource {
  Future<List<ProductEntity>> getProductsByCategory(String categoryId, {String? subcategoryId});

  Future<ProductEntity?> getProductById(String id);
}

@LazySingleton(as: ProductMockDatasource)
class ProductMockDatasourceImpl implements ProductMockDatasource {
  static const List<ProductEntity> _allProducts = [
    // Most Popular
    ProductEntity(
      id: 'mp_1',
      name: 'IBADAH Premium Chom Chom Sweet (500g)',
      price: 980,
      unit: '500g',
      categoryId: 'most_popular',
      iconKey: 'most_popular',
    ),
    ProductEntity(
      id: 'mp_2',
      name: 'Vegetable Samosa 10pcs',
      price: 480,
      unit: '400g',
      categoryId: 'most_popular',
      iconKey: 'most_popular',
    ),
    ProductEntity(
      id: 'mp_3',
      name: 'Dal Puri 10pcs',
      price: 350,
      unit: '10pcs',
      categoryId: 'most_popular',
      iconKey: 'most_popular',
    ),
    ProductEntity(
      id: 'mp_4',
      name: 'Aloo Puri 10pcs',
      price: 350,
      unit: '10pcs',
      categoryId: 'most_popular',
      iconKey: 'most_popular',
    ),

    // Meat & Fish
    ProductEntity(
      id: 'mf_1',
      name: 'Whole Chicken',
      price: 890,
      unit: '1kg',
      categoryId: 'meat_fish',
      iconKey: 'meat_fish',
      subcategoryId: 'chicken',
    ),
    ProductEntity(
      id: 'mf_2',
      name: 'Beef Cubes',
      price: 1200,
      unit: '500g',
      categoryId: 'meat_fish',
      iconKey: 'meat_fish',
      subcategoryId: 'beef',
    ),
    ProductEntity(
      id: 'mf_3',
      name: 'Frozen Tilapia Fish',
      price: 750,
      unit: '1kg',
      categoryId: 'meat_fish',
      iconKey: 'meat_fish',
      subcategoryId: 'fish_seafood',
    ),
    ProductEntity(
      id: 'mf_4',
      name: 'Goat Meat',
      price: 1650,
      unit: '1kg',
      categoryId: 'meat_fish',
      iconKey: 'meat_fish',
      subcategoryId: 'mutton',
    ),

    // Fruits & Vegetables
    ProductEntity(
      id: 'fv_1',
      name: 'Fresh Tomatoes',
      price: 320,
      unit: '1kg',
      categoryId: 'fruits_vegetables',
      iconKey: 'fruits_vegetables',
    ),
    ProductEntity(
      id: 'fv_2',
      name: 'Onions',
      price: 480,
      unit: '2kg',
      categoryId: 'fruits_vegetables',
      iconKey: 'fruits_vegetables',
    ),
    ProductEntity(
      id: 'fv_3',
      name: 'Potatoes',
      price: 420,
      unit: '2kg',
      categoryId: 'fruits_vegetables',
      iconKey: 'fruits_vegetables',
    ),
    ProductEntity(
      id: 'fv_4',
      name: 'Garlic',
      price: 380,
      unit: '500g',
      categoryId: 'fruits_vegetables',
      iconKey: 'fruits_vegetables',
    ),

    // Frozen Food
    ProductEntity(
      id: 'ff_1',
      name: 'Frozen Paratha 10pcs',
      price: 560,
      unit: '10pcs',
      categoryId: 'frozen_food',
      iconKey: 'frozen_food',
      subcategoryId: 'frozen_snacks',
    ),
    ProductEntity(
      id: 'ff_2',
      name: 'Frozen Mixed Vegetables',
      price: 420,
      unit: '1kg',
      categoryId: 'frozen_food',
      iconKey: 'frozen_food',
      subcategoryId: 'frozen_vegetables',
    ),
    ProductEntity(
      id: 'ff_3',
      name: 'Frozen Spring Rolls 20pcs',
      price: 680,
      unit: '20pcs',
      categoryId: 'frozen_food',
      iconKey: 'frozen_food',
      subcategoryId: 'frozen_snacks',
    ),

    // Beverages
    ProductEntity(
      id: 'bv_1',
      name: 'Mango Juice',
      price: 350,
      unit: '1L',
      categoryId: 'beverages',
      iconKey: 'beverages',
    ),
    ProductEntity(
      id: 'bv_2',
      name: 'Rooh Afza Syrup',
      price: 890,
      unit: '800ml',
      categoryId: 'beverages',
      iconKey: 'beverages',
    ),
    ProductEntity(
      id: 'bv_3',
      name: 'Mineral Water 6-pack',
      price: 480,
      unit: '1.5L x 6',
      categoryId: 'beverages',
      iconKey: 'beverages',
    ),

    // Masala & Spice
    ProductEntity(
      id: 'ms_1',
      name: 'MDH Chicken Curry Masala',
      price: 280,
      unit: '100g',
      categoryId: 'masala_spice',
      iconKey: 'masala_spice',
      subcategoryId: 'masala_mixes',
    ),
    ProductEntity(
      id: 'ms_2',
      name: 'Shan Biryani Masala',
      price: 260,
      unit: '100g',
      categoryId: 'masala_spice',
      iconKey: 'masala_spice',
      subcategoryId: 'masala_mixes',
    ),
    ProductEntity(
      id: 'ms_3',
      name: 'Whole Cumin Seeds',
      price: 340,
      unit: '200g',
      categoryId: 'masala_spice',
      iconKey: 'masala_spice',
      subcategoryId: 'whole_spices',
    ),
    ProductEntity(
      id: 'ms_4',
      name: 'Dry Red Chilli',
      price: 390,
      unit: '250g',
      categoryId: 'masala_spice',
      iconKey: 'masala_spice',
      subcategoryId: 'whole_spices',
    ),

    // Halal Products
    ProductEntity(
      id: 'hp_1',
      name: 'Halal Certified Beef Salami',
      price: 680,
      unit: '250g',
      categoryId: 'halal_products',
      iconKey: 'halal_products',
    ),
    ProductEntity(
      id: 'hp_2',
      name: 'Halal Chicken Nuggets',
      price: 720,
      unit: '500g',
      categoryId: 'halal_products',
      iconKey: 'halal_products',
    ),
    ProductEntity(
      id: 'hp_3',
      name: 'Halal Beef Sausages',
      price: 650,
      unit: '400g',
      categoryId: 'halal_products',
      iconKey: 'halal_products',
    ),

    // Rice & Grains
    ProductEntity(
      id: 'rg_1',
      name: 'Basmati Rice',
      price: 2400,
      unit: '5kg',
      categoryId: 'rice_grains',
      iconKey: 'rice_grains',
    ),
    ProductEntity(
      id: 'rg_2',
      name: 'Puffed Rice',
      price: 380,
      unit: '1kg',
      categoryId: 'rice_grains',
      iconKey: 'rice_grains',
    ),
    ProductEntity(
      id: 'rg_3',
      name: 'Red Lentils (Masoor Dal)',
      price: 420,
      unit: '1kg',
      categoryId: 'rice_grains',
      iconKey: 'rice_grains',
    ),
    ProductEntity(
      id: 'rg_4',
      name: 'Chickpeas',
      price: 360,
      unit: '1kg',
      categoryId: 'rice_grains',
      iconKey: 'rice_grains',
    ),

    // Snacks
    ProductEntity(
      id: 'sn_1',
      name: 'Vegetable Samosa 10pcs (IBADAH)',
      price: 480,
      unit: '400g',
      categoryId: 'snacks',
      iconKey: 'snacks',
      imageUrl: AssetPaths.demoProductImageVegetableSamosa,
    ),
  ];

  @override
  Future<List<ProductEntity>> getProductsByCategory(String categoryId, {String? subcategoryId}) async {
    return _allProducts
        .where(
          (product) =>
              product.categoryId == categoryId &&
              (subcategoryId == null || product.subcategoryId == subcategoryId),
        )
        .toList();
  }

  @override
  Future<ProductEntity?> getProductById(String id) async {
    for (final product in _allProducts) {
      if (product.id == id) return product;
    }
    return null;
  }
}
