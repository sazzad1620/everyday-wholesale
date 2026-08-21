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
};

IconData iconForCategory(String iconKey) => categoryIcons[iconKey] ?? Icons.category_rounded;
