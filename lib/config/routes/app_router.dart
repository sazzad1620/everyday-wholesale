import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/pages/account_page.dart';
import '../../features/account/presentation/pages/address_form_page.dart';
import '../../features/account/presentation/pages/edit_profile_page.dart';
import '../../features/account/presentation/pages/order_detail_page.dart';
import '../../features/account/presentation/pages/order_history_page.dart';
import '../../features/admin/presentation/pages/categories/admin_category_form_page.dart';
import '../../features/admin/presentation/pages/offers/admin_offer_form_page.dart';
import '../../features/admin/presentation/pages/orders/admin_order_detail_page.dart';
import '../../features/offer/presentation/pages/offers_page.dart';
import '../../features/admin/presentation/pages/products/admin_product_form_page.dart';
import '../../features/admin/presentation/pages/shell/admin_account_page.dart';
import '../../features/admin/presentation/pages/shell/admin_shell_page.dart';
import '../../features/auth/presentation/bloc/account_bloc.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/order_confirmation_page.dart';
import '../../features/home/domain/entities/category_entity.dart';
import '../../features/home/presentation/pages/categories_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/order/domain/entities/order_entity.dart';
import '../../features/product/domain/entities/product_entity.dart';
import '../../features/product/presentation/pages/product_detail_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/review/presentation/pages/my_reviews_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/support/presentation/pages/support_page.dart';
import '../../features/wishlist/presentation/pages/wishlist_page.dart';
import '../../shared/widgets/navigation/main_shell.dart';
import '../../core/utils/admin_session_hint.dart';
import '../di/injection_container.dart';
import 'admin_redirect.dart';
import 'go_router_refresh_stream.dart';
import 'route_paths.dart';
import 'tab_reset.dart';

/// Lets checkout/order-confirmation push on the root navigator instead of
/// the shell's nested one, so they render full-screen without the bottom
/// nav bar.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  // The web opens straight on the page in the address bar (`/` is the home
  // page itself); only the mobile apps start on the splash screen.
  initialLocation: kIsWeb ? null : RoutePaths.splash,
  // Re-evaluates `redirect` on every auth change, not just on navigation —
  // otherwise signing out while already on an admin page wouldn't kick you
  // out until the next tap.
  refreshListenable: GoRouterRefreshStream(getIt<AccountBloc>().stream),
  redirect: (context, state) {
    final account = getIt<AccountBloc>().state;
    return adminRedirect(
      location: state.matchedLocation,
      isInitializing: account.isInitializing,
      userIsAdmin: account.user?.isAdmin ?? false,
      rememberedAdmin: AdminSessionHint.isAdmin,
    );
  },
  routes: [
    GoRoute(
      path: RoutePaths.splash,
      builder: (context, state) => const SplashPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: RoutePaths.home, builder: (context, state) => const HomePage()),
            // The old home address — anything bookmarked or shared lands on `/`.
            GoRoute(path: RoutePaths.catalogue, redirect: (context, state) => RoutePaths.home),
            GoRoute(
              path: '${RoutePaths.catalogue}/category/:categoryId',
              builder: (context, state) {
                final extra = state.extra as CategoryProductsExtra?;
                return HiddenWhileTabReset(
                  child: ProductListPage(
                    categoryId: state.pathParameters['categoryId']!,
                    categoryName: extra?.categoryName,
                    subcategories: extra?.subcategories ?? const [],
                  ),
                );
              },
              routes: [
                GoRoute(
                  path: 'browse/:subcategoryId',
                  builder: (context, state) {
                    final extra = state.extra as ProductListExtra?;
                    return HiddenWhileTabReset(
                      child: ProductListPage(
                        categoryId: state.pathParameters['categoryId']!,
                        categoryName: extra?.categoryName,
                        subcategoryId: state.pathParameters['subcategoryId'],
                        subcategoryName: extra?.subcategoryName,
                        subcategories: extra?.subcategories ?? const [],
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'product/:productId',
                  builder: (context, state) {
                    final extra = state.extra as ProductDetailExtra?;
                    return HiddenWhileTabReset(
                      child: ProductDetailPage(
                        categoryId: state.pathParameters['categoryId']!,
                        productId: state.pathParameters['productId']!,
                        categoryName: extra?.categoryName,
                        subcategoryId: extra?.subcategoryId,
                        subcategoryName: extra?.subcategoryName,
                        subcategories: extra?.subcategories ?? const [],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: RoutePaths.categories, builder: (context, state) => const CategoriesPage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: RoutePaths.wishlist, builder: (context, state) => const WishlistPage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: RoutePaths.cart, builder: (context, state) => const CartPage())],
        ),
      ],
    ),
    GoRoute(
      path: RoutePaths.account,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AccountPage(),
    ),
    GoRoute(
      path: RoutePaths.admin,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AdminShellPage(),
    ),
    GoRoute(
      path: RoutePaths.adminAccount,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AdminAccountPage(),
    ),
    GoRoute(
      path: RoutePaths.adminCategoryForm,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => AdminCategoryFormPage(initial: state.extra as CategoryEntity?),
    ),
    GoRoute(
      path: RoutePaths.adminProductForm,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => AdminProductFormPage(initial: state.extra as ProductEntity?),
    ),
    GoRoute(
      path: RoutePaths.adminOfferForm,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AdminOfferFormPage(),
    ),
    GoRoute(
      path: RoutePaths.offers,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const OffersPage(),
    ),
    GoRoute(
      path: RoutePaths.orderHistory,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const OrderHistoryPage(),
    ),
    GoRoute(
      path: RoutePaths.myReviews,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const MyReviewsPage(),
    ),
    GoRoute(
      path: RoutePaths.orderDetail,
      parentNavigatorKey: rootNavigatorKey,
      // `extra` only carries the order when reached via a real push (see
      // `_OrderCard.onTap`); a direct/reloaded URL with none falls back to
      // the list instead of crashing on a null cast.
      builder: (context, state) {
        final order = state.extra as OrderEntity?;
        return order == null ? const OrderHistoryPage() : OrderDetailPage(order: order);
      },
    ),
    GoRoute(
      path: RoutePaths.adminOrderDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final order = state.extra as OrderEntity?;
        return order == null ? const AdminShellPage() : AdminOrderDetailPage(order: order);
      },
    ),
    GoRoute(
      path: RoutePaths.accountAddress,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AddressFormPage(),
    ),
    GoRoute(
      path: RoutePaths.editProfile,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: RoutePaths.support,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SupportPage(),
    ),
    GoRoute(
      path: RoutePaths.checkout,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CheckoutPage(),
    ),
    GoRoute(
      path: RoutePaths.orderConfirmation,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => OrderConfirmationPage(args: state.extra as OrderConfirmationArgs?),
    ),
  ],
);
