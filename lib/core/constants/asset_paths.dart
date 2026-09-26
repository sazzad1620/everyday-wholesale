abstract final class AssetPaths {
  static const String translationsPath = 'assets/translations';
  static const String logo = 'assets/images/logo.png';

  /// Demo-only stand-in for what an admin-uploaded category photo will look
  /// like once Firebase Storage is wired up (a real `https://` URL then).
  static const String demoCategoryImageMeatFish = 'assets/images/category_meat_fish.webp';

  /// Card image of the virtual Most Popular category — it has no
  /// `categories` doc, so there's nowhere for an admin to upload one.
  static const String mostPopularCategoryImage = 'assets/images/category_most_popular.webp';

  /// Demo-only stand-in for what an admin-uploaded product photo will look
  /// like once Firebase Storage is wired up (a real `https://` URL then).
  static const String demoProductImageVegetableSamosa = 'assets/images/product_vegetable_samosa.jpg';
}
