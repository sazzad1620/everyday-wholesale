abstract final class RoutePaths {
  /// Mobile start-up screen only: on the web the app opens straight on [home].
  static const String splash = '/splash';

  /// The storefront home. (Used to be `/home`; that address now redirects here.)
  static const String home = '/';

  /// Where the catalogue pages live: `/home/category/...` - kept as it was so
  /// every link already shared or indexed keeps working.
  static const String catalogue = '/home';
  static const String account = '/account';
  static const String admin = '/admin';
  static const String adminAccount = '/admin/account';
  static const String adminCategoryForm = '/admin/categories/form';
  static const String adminProductForm = '/admin/products/form';
  static const String adminOfferForm = '/admin/offers/form';
  static const String offers = '/offers';
  static const String orderHistory = '/account/order-history';
  static const String myReviews = '/account/my-reviews';
  static const String orderDetail = '/account/order-detail';
  static const String adminOrderDetail = '/admin/orders/detail';
  static const String accountAddress = '/account/address';
  static const String editProfile = '/account/edit-profile';
  static const String categories = '/categories';
  static const String wishlist = '/wishlist';
  static const String cart = '/cart';
  static const String support = '/support';
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order-confirmation';

  static String categoryProducts(String categoryId) => '$catalogue/category/$categoryId';

  static String subcategoryProducts(String categoryId, String subcategoryId) =>
      '$catalogue/category/$categoryId/browse/$subcategoryId';

  static String productDetail(String categoryId, String productId) =>
      '$catalogue/category/$categoryId/product/$productId';
}
