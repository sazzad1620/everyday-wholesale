import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/pages/account_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/order_confirmation_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/product/presentation/pages/product_detail_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/wishlist/presentation/pages/wishlist_page.dart';
import '../../shared/widgets/navigation/main_shell.dart';
import 'route_paths.dart';

/// Lets checkout/order-confirmation push on the root navigator instead of
/// the shell's nested one, so they render full-screen without the bottom
/// nav bar.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RoutePaths.splash,
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
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => const HomePage(),
              routes: [
                GoRoute(
                  path: 'category/:categoryId',
                  builder: (context, state) {
                    final extra = state.extra as CategoryProductsExtra?;
                    return ProductListPage(
                      categoryId: state.pathParameters['categoryId']!,
                      categoryName: extra?.categoryName,
                      subcategories: extra?.subcategories ?? const [],
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'browse/:subcategoryId',
                      builder: (context, state) {
                        final extra = state.extra as ProductListExtra?;
                        return ProductListPage(
                          categoryId: state.pathParameters['categoryId']!,
                          categoryName: extra?.categoryName,
                          subcategoryId: state.pathParameters['subcategoryId'],
                          subcategoryName: extra?.subcategoryName,
                          subcategories: extra?.subcategories ?? const [],
                        );
                      },
                    ),
                    GoRoute(
                      path: 'product/:productId',
                      builder: (context, state) {
                        final extra = state.extra as ProductDetailExtra?;
                        return ProductDetailPage(
                          categoryId: state.pathParameters['categoryId']!,
                          productId: state.pathParameters['productId']!,
                          categoryName: extra?.categoryName,
                          subcategoryId: extra?.subcategoryId,
                          subcategoryName: extra?.subcategoryName,
                          subcategories: extra?.subcategories ?? const [],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
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
      path: RoutePaths.checkout,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CheckoutPage(),
    ),
    GoRoute(
      path: RoutePaths.orderConfirmation,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const OrderConfirmationPage(),
    ),
  ],
);
