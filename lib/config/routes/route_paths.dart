abstract final class RoutePaths {
  static const String splash = '/';
  static const String home = '/home';
  static const String wishlist = '/wishlist';
  static const String cart = '/cart';

  static String categoryProducts(String categoryId) => '$home/category/$categoryId';

  static String categoryBrowse(String categoryId) => '$home/category/$categoryId/browse';

  static String subcategoryProducts(String categoryId, String subcategoryId) =>
      '$home/category/$categoryId/browse/$subcategoryId';
}
