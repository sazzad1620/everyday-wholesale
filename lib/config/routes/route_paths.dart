abstract final class RoutePaths {
  static const String splash = '/';
  static const String home = '/home';
  static const String account = '/account';
  static const String orderHistory = '/account/order-history';
  static const String wishlist = '/wishlist';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order-confirmation';

  static String categoryProducts(String categoryId) => '$home/category/$categoryId';

  static String subcategoryProducts(String categoryId, String subcategoryId) =>
      '$home/category/$categoryId/browse/$subcategoryId';

  static String productDetail(String categoryId, String productId) =>
      '$home/category/$categoryId/product/$productId';
}
