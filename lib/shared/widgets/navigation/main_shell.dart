import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/di/injection_container.dart';
import '../../../core/usecase/usecase.dart';
import '../../../features/home/domain/entities/category_entity.dart';
import '../../../features/home/domain/usecases/get_categories_usecase.dart';
import '../../../features/home/presentation/widgets/category_drawer.dart';
import '../../theme/app_colors.dart';
import 'main_bottom_nav_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
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
      drawer: FutureBuilder<List<CategoryEntity>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          return CategoryDrawer(categories: snapshot.data ?? const []);
        },
      ),
      body: widget.navigationShell,
      bottomNavigationBar: MainBottomNavBar(
        navigationShell: widget.navigationShell,
        onCategoryTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    );
  }
}
