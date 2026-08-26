import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'standalone_shell_scaffold.dart';

/// Thin wrapper around [StandaloneShellScaffold] for the [StatefulShellRoute]
/// branches (Home/Wishlist/Cart) — passes the branch content as both the body
/// and the [StandaloneShellScaffold.navigationShell], so the bottom nav knows
/// which branch is selected and switches between them via `goBranch`.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return StandaloneShellScaffold(body: navigationShell, navigationShell: navigationShell);
  }
}
