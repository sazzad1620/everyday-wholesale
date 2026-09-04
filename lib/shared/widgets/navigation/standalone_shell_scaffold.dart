import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/responsive/breakpoints.dart';
import '../../theme/app_colors.dart';
import 'categories_cache.dart';
import 'category_drawer.dart';
import 'main_bottom_nav_bar.dart';
import 'main_menu_drawer.dart';

/// The drawer/end-drawer/bottom-nav chrome shared by [MainShell]'s branches
/// and by full-screen pages pushed on the root navigator (e.g. the account
/// and order-history pages) that still want the same look — those pages pass
/// no [navigationShell] since they aren't one of the shell's branches, so
/// [MainBottomNavBar] renders with nothing selected and navigates via
/// `context.go` instead of switching branches.
///
/// At width >= [AppBreakpoints.mobile] the bottom bar disappears (its
/// destinations move into [AppHeader] instead — see there) and the
/// hamburger/drawer give way to a persistent [DesktopSidebar], but that
/// sidebar is *not* added here: it needs to sit below each page's header,
/// not beside the whole page, so [DesktopBody] wraps each page's own content
/// instead. This widget only owns the drawer/bottom-nav, which apply
/// uniformly regardless of what a given page's header/content look like.
class StandaloneShellScaffold extends StatefulWidget {
  const StandaloneShellScaffold({super.key, required this.body, this.navigationShell});

  final Widget body;
  final StatefulNavigationShell? navigationShell;

  @override
  State<StandaloneShellScaffold> createState() => _StandaloneShellScaffoldState();
}

class _StandaloneShellScaffoldState extends State<StandaloneShellScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const MainMenuDrawer(),
      endDrawer: FutureBuilder(
        future: cachedCategories(),
        builder: (context, snapshot) {
          return CategoryDrawer(categories: snapshot.data ?? const []);
        },
      ),
      body: widget.body,
      bottomNavigationBar: isWide
          ? null
          : MainBottomNavBar(
              navigationShell: widget.navigationShell,
              onCategoryTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
    );
  }
}
