import 'package:go_router/go_router.dart';

import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/home/domain/entities/category_entity.dart';
import '../../features/home/presentation/pages/category_landing_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/wishlist/presentation/pages/wishlist_page.dart';
import '../../shared/widgets/navigation/main_shell.dart';
import 'route_paths.dart';

final GoRouter appRouter = GoRouter(
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
                  builder: (context, state) => ProductListPage(
                    categoryId: state.pathParameters['categoryId']!,
                    categoryName: state.extra as String?,
                  ),
                  routes: [
                    GoRoute(
                      path: 'browse',
                      builder: (context, state) => CategoryLandingPage(category: state.extra as CategoryEntity),
                    ),
                    GoRoute(
                      path: 'browse/:subcategoryId',
                      builder: (context, state) {
                        final extra = state.extra as ProductListExtra?;
                        return ProductListPage(
                          categoryId: state.pathParameters['categoryId']!,
                          categoryName: extra?.categoryName,
                          subcategoryId: state.pathParameters['subcategoryId'],
                          subcategoryName: extra?.subcategoryName,
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
  ],
);
