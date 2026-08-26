import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/di/injection_container.dart';
import '../../../core/usecase/usecase.dart';
import '../../../features/home/domain/entities/category_entity.dart';
import '../../../features/home/domain/usecases/get_categories_usecase.dart';
import '../../theme/app_colors.dart';
import 'category_drawer.dart';
import 'main_bottom_nav_bar.dart';
import 'main_menu_drawer.dart';

/// The drawer/end-drawer/bottom-nav chrome shared by [MainShell]'s branches
/// and by full-screen pages pushed on the root navigator (e.g. the account
/// and order-history pages) that still want the same look — those pages pass
/// no [navigationShell] since they aren't one of the shell's branches, so
/// [MainBottomNavBar] renders with nothing selected and navigates via
/// `context.go` instead of switching branches.
class StandaloneShellScaffold extends StatefulWidget {
  const StandaloneShellScaffold({super.key, required this.body, this.navigationShell});

  final Widget body;
  final StatefulNavigationShell? navigationShell;

  @override
  State<StandaloneShellScaffold> createState() => _StandaloneShellScaffoldState();
}

class _StandaloneShellScaffoldState extends State<StandaloneShellScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final Future<List<CategoryEntity>> _categoriesFuture = _loadCategories();

  Future<List<CategoryEntity>> _loadCategories() async {
    final result = await getIt<GetCategoriesUseCase>()(const NoParams());
    return result.match((_) => const [], (categories) => categories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const MainMenuDrawer(),
      endDrawer: FutureBuilder<List<CategoryEntity>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          return CategoryDrawer(categories: snapshot.data ?? const []);
        },
      ),
      body: widget.body,
      bottomNavigationBar: MainBottomNavBar(
        navigationShell: widget.navigationShell,
        onCategoryTap: () => _scaffoldKey.currentState?.openEndDrawer(),
      ),
    );
  }
}
