import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/pages/account_page.dart';
import '../../features/account/presentation/pages/order_history_page.dart';
import '../../features/admin/presentation/pages/admin_category_form_page.dart';
import '../../features/admin/presentation/pages/admin_product_form_page.dart';
import '../../features/admin/presentation/pages/admin_shell_page.dart';
import '../../features/auth/presentation/bloc/account_bloc.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/order_confirmation_page.dart';
import '../../features/home/domain/entities/category_entity.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/order/domain/entities/order_entity.dart';
import '../../features/product/domain/entities/product_entity.dart';
import '../../features/product/presentation/pages/product_detail_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/wishlist/presentation/pages/wishlist_page.dart';
import '../../shared/widgets/navigation/main_shell.dart';
import '../di/injection_container.dart';
import 'go_router_refresh_stream.dart';
import 'route_paths.dart';

/// Lets checkout/order-confirmation push on the root navigator instead of
/// the shell's nested one, so they render full-screen without the bottom
/// nav bar.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RoutePaths.splash,
  // Re-evaluates `redirect` on every auth change, not just on navigation —
  // otherwise signing out while already on an admin page wouldn't kick you
  // out until the next tap.
  refreshListenable: GoRouterRefreshStream(getIt<AccountBloc>().stream),
  redirect: (context, state) {
    if (!state.matchedLocation.startsWith(RoutePaths.admin)) return null;
    final isAdmin = getIt<AccountBloc>().state.user?.isAdmin ?? false;
    return isAdmin ? null : RoutePaths.home;
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
      path: RoutePaths.admin,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AdminShellPage(),
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
      path: RoutePaths.orderHistory,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const OrderHistoryPage(),
    ),
    GoRoute(
      path: RoutePaths.checkout,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CheckoutPage(),
    ),
    GoRoute(
      path: RoutePaths.orderConfirmation,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => OrderConfirmationPage(order: state.extra as OrderEntity?),
    ),
  ],
);
