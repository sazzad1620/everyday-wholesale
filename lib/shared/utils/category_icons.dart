import 'package:flutter/material.dart';

/// Maps a category/product `iconKey` to its display icon. Kept separate from
/// domain entities so their data stays serializable (Firestore-ready) while
/// presentation decides how each key is drawn. Shared across `home` (category
/// cards/drawer) and `product` (product cards) since both key off the same
/// category taxonomy.
const Map<String, IconData> categoryIcons = {
  'most_popular': Icons.star_rounded,
  'meat_fish': Icons.set_meal_rounded,
  'fruits_vegetables': Icons.eco_rounded,
  'frozen_food': Icons.ac_unit_rounded,
  'beverages': Icons.local_drink_rounded,
  'masala_spice': Icons.local_fire_department_rounded,
  'halal_products': Icons.verified_rounded,
  'rice_grains': Icons.grain_rounded,
  'snacks': Icons.bakery_dining_rounded,
  // General-purpose grocery icons available for new categories created from
  // the admin panel (not tied to an existing category id).
  'dairy_eggs': Icons.egg_rounded,
  'bakery': Icons.cake_rounded,
  'household': Icons.cleaning_services_rounded,
  'personal_care': Icons.spa_rounded,
  'baby_care': Icons.child_care_rounded,
  'health_wellness': Icons.favorite_rounded,
  'pantry_staples': Icons.kitchen_rounded,
  'canned_goods': Icons.inventory_rounded,
  'condiments_sauces': Icons.liquor_rounded,
  'breakfast': Icons.free_breakfast_rounded,
  'organic': Icons.energy_savings_leaf_rounded,
};

IconData iconForCategory(String iconKey) => categoryIcons[iconKey] ?? Icons.category_rounded;
