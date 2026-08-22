import 'package:injectable/injectable.dart';

import '../../../../core/constants/asset_paths.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_review_entity.dart';

abstract class ProductMockDatasource {
  Future<List<ProductEntity>> getProductsByCategory(String categoryId, {String? subcategoryId});

  Future<ProductEntity?> getProductById(String id);
}

@LazySingleton(as: ProductMockDatasource)
class ProductMockDatasourceImpl implements ProductMockDatasource {
  static const List<ProductEntity> _allProducts = [
    // Most Popular — condition/origin shared per category until admin-editable.
    ProductEntity(
      id: 'mp_1',
      name: 'IBADAH Premium Chom Chom Sweet (500g)',
      price: 980,
      unit: '500g',
      categoryId: 'most_popular',
      iconKey: 'most_popular',
      condition: 'Freshly Prepared',
      origin: 'Bangladesh',
      description:
          'A rich, syrup-soaked Bengali sweet made the traditional way — soft, delicately sweet, and perfect '
          'for celebrations or an everyday treat.',
      reviews: [
        ProductReviewEntity(reviewerName: 'Rashed Karim', rating: 5, comment: 'Tastes just like home. Will order again!'),
        ProductReviewEntity(reviewerName: 'Nusrat Jahan', rating: 4, comment: 'Sweet and fresh, arrived well packed.'),
        ProductReviewEntity(reviewerName: 'Imran Hossain', rating: 5, comment: 'Best chom chom I have had in Japan.'),
      ],
    ),
    ProductEntity(
      id: 'mp_2',
      name: 'Vegetable Samosa 10pcs',
      price: 480,
      unit: '400g',
      categoryId: 'most_popular',
      iconKey: 'most_popular',
      condition: 'Freshly Prepared',
      origin: 'Bangladesh',
      description: 'One of our best-selling picks, loved by regular customers for its quality and value.',
    ),
    ProductEntity(
      id: 'mp_3',
      name: 'Dal Puri 10pcs',
      price: 350,
      unit: '10pcs',
      categoryId: 'most_popular',
      iconKey: 'most_popular',
      condition: 'Freshly Prepared',
      origin: 'Bangladesh',
      description: 'One of our best-selling picks, loved by regular customers for its quality and value.',
    ),
    ProductEntity(
      id: 'mp_4',
      name: 'Aloo Puri 10pcs',
      price: 350,
      unit: '10pcs',
      categoryId: 'most_popular',
      iconKey: 'most_popular',
      condition: 'Freshly Prepared',
      origin: 'Bangladesh',
      description: 'One of our best-selling picks, loved by regular customers for its quality and value.',
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
      condition: 'Fresh',
      origin: 'Brazil',
      description:
          'Halal-certified whole chicken, expertly cut for convenience and sourced from trusted suppliers. Ideal '
          'for roasting, curries, or grilling, and a favourite among our regular customers.',
      reviews: [
        ProductReviewEntity(reviewerName: 'Shakil Ahmed', rating: 5, comment: 'Very fresh and cut exactly as described.'),
        ProductReviewEntity(reviewerName: 'Maisha Tabassum', rating: 5, comment: 'Great quality, perfect for curry.'),
        ProductReviewEntity(reviewerName: 'Tanvir Alam', rating: 4, comment: 'Good value for 1kg, delivery was quick.'),
      ],
    ),
    ProductEntity(
      id: 'mf_2',
      name: 'Beef Cubes',
      price: 1200,
      unit: '500g',
      categoryId: 'meat_fish',
      iconKey: 'meat_fish',
      subcategoryId: 'beef',
      condition: 'Fresh',
      origin: 'Brazil',
      description: 'Sourced and prepared to strict Halal standards, ready for your favourite recipes.',
    ),
    ProductEntity(
      id: 'mf_3',
      name: 'Frozen Tilapia Fish',
      price: 750,
      unit: '1kg',
      categoryId: 'meat_fish',
      iconKey: 'meat_fish',
      subcategoryId: 'fish_seafood',
      condition: 'Fresh',
      origin: 'Brazil',
      description: 'Sourced and prepared to strict Halal standards, ready for your favourite recipes.',
    ),
    ProductEntity(
      id: 'mf_4',
      name: 'Goat Meat',
      price: 1650,
      unit: '1kg',
      categoryId: 'meat_fish',
      iconKey: 'meat_fish',
      subcategoryId: 'mutton',
      condition: 'Fresh',
      origin: 'Brazil',
      description: 'Sourced and prepared to strict Halal standards, ready for your favourite recipes.',
    ),

    // Fruits & Vegetables
    ProductEntity(
      id: 'fv_1',
      name: 'Fresh Tomatoes',
      price: 320,
      unit: '1kg',
      categoryId: 'fruits_vegetables',
      iconKey: 'fruits_vegetables',
      condition: 'Fresh',
      origin: 'Bangladesh',
      description: 'Picked fresh and kept crisp, straight from trusted local suppliers.',
    ),
    ProductEntity(
      id: 'fv_2',
      name: 'Onions',
      price: 480,
      unit: '2kg',
      categoryId: 'fruits_vegetables',
      iconKey: 'fruits_vegetables',
      condition: 'Fresh',
      origin: 'Bangladesh',
      description: 'Picked fresh and kept crisp, straight from trusted local suppliers.',
    ),
    ProductEntity(
      id: 'fv_3',
      name: 'Potatoes',
      price: 420,
      unit: '2kg',
      categoryId: 'fruits_vegetables',
      iconKey: 'fruits_vegetables',
      condition: 'Fresh',
      origin: 'Bangladesh',
      description: 'Picked fresh and kept crisp, straight from trusted local suppliers.',
    ),
    ProductEntity(
      id: 'fv_4',
      name: 'Garlic',
      price: 380,
      unit: '500g',
      categoryId: 'fruits_vegetables',
      iconKey: 'fruits_vegetables',
      condition: 'Fresh',
      origin: 'Bangladesh',
      description: 'Picked fresh and kept crisp, straight from trusted local suppliers.',
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
      condition: 'Frozen',
      origin: 'Bangladesh',
      description: 'Flash-frozen to lock in freshness — just heat and serve.',
    ),
    ProductEntity(
      id: 'ff_2',
      name: 'Frozen Mixed Vegetables',
      price: 420,
      unit: '1kg',
      categoryId: 'frozen_food',
      iconKey: 'frozen_food',
      subcategoryId: 'frozen_vegetables',
      condition: 'Frozen',
      origin: 'Bangladesh',
      description: 'Flash-frozen to lock in freshness — just heat and serve.',
    ),
    ProductEntity(
      id: 'ff_3',
      name: 'Frozen Spring Rolls 20pcs',
      price: 680,
      unit: '20pcs',
      categoryId: 'frozen_food',
      iconKey: 'frozen_food',
      subcategoryId: 'frozen_snacks',
      condition: 'Frozen',
      origin: 'Bangladesh',
      description: 'Flash-frozen to lock in freshness — just heat and serve.',
      inStock: false,
    ),

    // Beverages
    ProductEntity(
      id: 'bv_1',
      name: 'Mango Juice',
      price: 350,
      unit: '1L',
      categoryId: 'beverages',
      iconKey: 'beverages',
      condition: 'Ambient',
      origin: 'Bangladesh',
      description: 'A refreshing pick for any time of day, stocked fresh at every restock.',
    ),
    ProductEntity(
      id: 'bv_2',
      name: 'Rooh Afza Syrup',
      price: 890,
      unit: '800ml',
      categoryId: 'beverages',
      iconKey: 'beverages',
      condition: 'Ambient',
      origin: 'Bangladesh',
      description: 'A refreshing pick for any time of day, stocked fresh at every restock.',
    ),
    ProductEntity(
      id: 'bv_3',
      name: 'Mineral Water 6-pack',
      price: 480,
      unit: '1.5L x 6',
      categoryId: 'beverages',
      iconKey: 'beverages',
      condition: 'Ambient',
      origin: 'Bangladesh',
      description: 'A refreshing pick for any time of day, stocked fresh at every restock.',
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
      condition: 'Dry / Packaged',
      origin: 'India',
      description: 'Carefully sourced and blended for authentic, consistent flavour in every batch.',
    ),
    ProductEntity(
      id: 'ms_2',
      name: 'Shan Biryani Masala',
      price: 260,
      unit: '100g',
      categoryId: 'masala_spice',
      iconKey: 'masala_spice',
      subcategoryId: 'masala_mixes',
      condition: 'Dry / Packaged',
      origin: 'India',
      description: 'Carefully sourced and blended for authentic, consistent flavour in every batch.',
    ),
    ProductEntity(
      id: 'ms_3',
      name: 'Whole Cumin Seeds',
      price: 340,
      unit: '200g',
      categoryId: 'masala_spice',
      iconKey: 'masala_spice',
      subcategoryId: 'whole_spices',
      condition: 'Dry / Packaged',
      origin: 'India',
      description: 'Carefully sourced and blended for authentic, consistent flavour in every batch.',
    ),
    ProductEntity(
      id: 'ms_4',
      name: 'Dry Red Chilli',
      price: 390,
      unit: '250g',
      categoryId: 'masala_spice',
      iconKey: 'masala_spice',
      subcategoryId: 'whole_spices',
      condition: 'Dry / Packaged',
      origin: 'India',
      description: 'Carefully sourced and blended for authentic, consistent flavour in every batch.',
    ),

    // Halal Products
    ProductEntity(
      id: 'hp_1',
      name: 'Halal Certified Beef Salami',
      price: 680,
      unit: '250g',
      categoryId: 'halal_products',
      iconKey: 'halal_products',
      condition: 'Frozen',
      origin: 'Brazil',
      description:
          'Halal-certified beef salami, thinly sliced and ready to serve — great for sandwiches, platters, or a '
          'quick snack.',
      reviews: [
        ProductReviewEntity(reviewerName: 'Farhana Akter', rating: 5, comment: 'Delicious and properly Halal certified.'),
        ProductReviewEntity(reviewerName: 'Kamal Hasan', rating: 4, comment: 'Nice texture, good for sandwiches.'),
      ],
    ),
    ProductEntity(
      id: 'hp_2',
      name: 'Halal Chicken Nuggets',
      price: 720,
      unit: '500g',
      categoryId: 'halal_products',
      iconKey: 'halal_products',
      condition: 'Frozen',
      origin: 'Brazil',
      description: 'Halal-certified and prepared to the highest quality standards you can trust.',
    ),
    ProductEntity(
      id: 'hp_3',
      name: 'Halal Beef Sausages',
      price: 650,
      unit: '400g',
      categoryId: 'halal_products',
      iconKey: 'halal_products',
      condition: 'Frozen',
      origin: 'Brazil',
      description: 'Halal-certified and prepared to the highest quality standards you can trust.',
    ),

    // Rice & Grains
    ProductEntity(
      id: 'rg_1',
      name: 'Basmati Rice',
      price: 2400,
      unit: '5kg',
      categoryId: 'rice_grains',
      iconKey: 'rice_grains',
      condition: 'Dry / Packaged',
      origin: 'India',
      description:
          'Long-grain aromatic Basmati rice, aged for extra fragrance and fluffiness — a pantry essential for '
          'biryani, pulao, and everyday meals.',
      reviews: [
        ProductReviewEntity(reviewerName: 'Sabbir Rahman', rating: 5, comment: 'Excellent aroma, cooks perfectly every time.'),
        ProductReviewEntity(reviewerName: 'Ayesha Siddika', rating: 4, comment: 'Good quality rice, a bit pricey but worth it.'),
        ProductReviewEntity(reviewerName: 'Jahid Hasan', rating: 5, comment: 'Best basmati rice available locally.'),
      ],
    ),
    ProductEntity(
      id: 'rg_2',
      name: 'Puffed Rice',
      price: 380,
      unit: '1kg',
      categoryId: 'rice_grains',
      iconKey: 'rice_grains',
      condition: 'Dry / Packaged',
      origin: 'India',
      description: 'A pantry staple, sourced for consistent quality and great everyday value.',
    ),
    ProductEntity(
      id: 'rg_3',
      name: 'Red Lentils (Masoor Dal)',
      price: 420,
      unit: '1kg',
      categoryId: 'rice_grains',
      iconKey: 'rice_grains',
      condition: 'Dry / Packaged',
      origin: 'India',
      description: 'A pantry staple, sourced for consistent quality and great everyday value.',
    ),
    ProductEntity(
      id: 'rg_4',
      name: 'Chickpeas',
      price: 360,
      unit: '1kg',
      categoryId: 'rice_grains',
      iconKey: 'rice_grains',
      condition: 'Dry / Packaged',
      origin: 'India',
      description: 'A pantry staple, sourced for consistent quality and great everyday value.',
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
      condition: 'Ambient',
      origin: 'Bangladesh',
      description: 'A tasty, ready-to-cook snack the whole family will enjoy.',
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
