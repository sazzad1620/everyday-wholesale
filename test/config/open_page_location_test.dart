import 'package:everyday_wholesale/shared/widgets/navigation/main_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The bottom bar reads the open page from `currentConfiguration.last
/// .matchedLocation`. That must be the page on TOP — also when it was pushed
/// over a tab from another tab (a category opened from the Category tab),
/// where `currentConfiguration.uri` still names the tab underneath.
void main() {
  late StatefulNavigationShell shell;

  testWidgets('a category pushed from the Category tab is seen as the open page, and no tab is selected', (tester) async {
    final router = GoRouter(
      initialLocation: '/categories',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => shell = navigationShell,
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/', builder: (_, _) => const Text('home')),
                GoRoute(path: '/home/category/:id', builder: (_, _) => const Text('category page')),
              ],
            ),
            StatefulShellBranch(routes: [GoRoute(path: '/categories', builder: (_, _) => const Text('categories'))]),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // What the bottom bar does: rebuild whenever the delegate notifies.
    final seen = <String>[];
    void record() => seen.add(router.routerDelegate.currentConfiguration.last.matchedLocation);
    router.routerDelegate.addListener(record);
    addTearDown(() => router.routerDelegate.removeListener(record));

    String open() => router.routerDelegate.currentConfiguration.last.matchedLocation;
    int selected(int branch) => selectedTabIndex(branchIndex: branch, path: open());

    expect(open(), '/categories');
    expect(selected(1), 1, reason: 'the Category tab is selected on its own page');

    router.push('/home/category/rice');
    await tester.pumpAndSettle();
    expect(find.text('category page'), findsOneWidget);
    expect(open(), '/home/category/rice');
    expect(selected(1), -1, reason: 'pushed from the Category tab: nothing selected');
    expect(selected(0), -1);
    expect(seen, contains('/home/category/rice'), reason: 'the delegate notifies listeners when a page is pushed, so the bar rebuilds');

    router.pop();
    await tester.pumpAndSettle();
    expect(selected(1), 1, reason: 'back on the Category page, its tab is selected again');
  });

  testWidgets('tapping a tab from any page opens that tab\x27s top-level page, with nothing left pushed', (tester) async {
    final router = GoRouter(
      initialLocation: '/categories',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => shell = navigationShell,
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/', builder: (_, _) => const Text('home')),
                GoRoute(path: '/home/category/:id', builder: (_, _) => const Text('category page')),
              ],
            ),
            StatefulShellBranch(routes: [GoRoute(path: '/categories', builder: (_, _) => const Text('categories'))]),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    String open() => router.routerDelegate.currentConfiguration.last.matchedLocation;

    // On a category list pushed over the Category tab, tap Home.
    router.push('/home/category/rice');
    await tester.pumpAndSettle();
    shell.goBranch(0, initialLocation: true);
    await tester.pumpAndSettle();
    expect(open(), '/');
    expect(find.text('home'), findsOneWidget);

    // Open a category on the Home tab, then tap Category: its top-level page,
    // and nothing from the Home tab left on top of it.
    router.go('/home/category/rice');
    await tester.pumpAndSettle();
    shell.goBranch(1, initialLocation: true);
    await tester.pumpAndSettle();
    expect(open(), '/categories');
    expect(find.text('categories'), findsOneWidget);
    expect(find.text('category page'), findsNothing);

    // Back on Home from there: its top-level page again, not the category it was on.
    shell.goBranch(0, initialLocation: true);
    await tester.pumpAndSettle();
    expect(open(), '/');
  });
}
