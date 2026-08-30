abstract final class RoutePaths {
  static const String splash = '/';
  static const String home = '/home';
  static const String account = '/account';
  static const String admin = '/admin';
  static const String adminAccount = '/admin/account';
  static const String adminCategoryForm = '/admin/categories/form';
  static const String adminProductForm = '/admin/products/form';
  static const String orderHistory = '/account/order-history';
  static const String myReviews = '/account/my-reviews';
  static const String orderDetail = '/account/order-detail';
  static const String adminOrderDetail = '/admin/orders/detail';
  static const String accountAddress = '/account/address';
  static const String editProfile = '/account/edit-profile';
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
