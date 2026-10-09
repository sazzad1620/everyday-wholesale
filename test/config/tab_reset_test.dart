import 'package:everyday_wholesale/config/routes/tab_reset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Home -> product -> Category tab -> Home tab: the product page must not be
/// seen sliding out over the Home page.
void main() {
  late StatefulNavigationShell shell;

  GoRouter buildRouter({required bool wrapped}) => GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => shell = navigationShell,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const Text('home page')),
              GoRoute(
                path: '/home/category/:id/product/:pid',
                builder: (_, _) =>
                    wrapped ? const HiddenWhileTabReset(child: Text('product page')) : const Text('product page'),
              ),
            ],
          ),
          StatefulShellBranch(routes: [GoRoute(path: '/categories', builder: (_, _) => const Text('categories page'))]),
        ],
      ),
    ],
  );

  Future<void> run(WidgetTester tester, {required bool wrapped}) async {
    final router = buildRouter(wrapped: wrapped);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.go('/home/category/rice/product/p1'); // open a product from Home
    await tester.pumpAndSettle();
    TabReset.run(() => shell.goBranch(1, initialLocation: true)); // Category tab
    await tester.pumpAndSettle();
    expect(find.text('categories page'), findsOneWidget);

    TabReset.run(() => shell.goBranch(0, initialLocation: true)); // back to the Home tab
    await tester.pump(); // first frame after the tap
    await tester.pump(const Duration(milliseconds: 120)); // mid page transition
  }

  testWidgets('with HiddenWhileTabReset the old product page is not on screen when Home opens', (tester) async {
    await run(tester, wrapped: true);
    expect(find.text('home page'), findsOneWidget);
    expect(find.text('product page'), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('home page'), findsOneWidget);
  });

  testWidgets('without it the product page is still visible mid-transition (the bug this prevents)', (tester) async {
    await run(tester, wrapped: false);
    expect(find.text('product page'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('pages are visible again right after, so a quick next tap on a product is never hidden', (tester) async {
    await run(tester, wrapped: true);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(TabReset.active.value, isFalse);
  });
}
