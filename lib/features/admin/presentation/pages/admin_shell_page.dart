import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/responsive/responsive_builder.dart';
import '../../../../shared/theme/app_colors.dart';
import '../widgets/admin_header.dart';
import 'admin_categories_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_orders_page.dart';
import 'admin_products_page.dart';

/// Root of the admin/manager side — a responsive nav shell (bottom nav on
/// phone, a side rail on tablet/desktop, using the same [ResponsiveBuilder]
/// the rest of the app uses) around 4 sections. Reached only via `/admin`,
/// which is route-guarded to `role: admin` accounts (see `app_router.dart`).
///
/// Deliberately its own shell, not [MainShell]/[StandaloneShellScaffold] —
/// this is a back-office context (no drawer, no cart, no category browsing),
/// so reusing the customer chrome would drag in irrelevant pieces.
class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _selectedIndex = 0;

  static const _pages = [AdminDashboardPage(), AdminProductsPage(), AdminCategoriesPage(), AdminOrdersPage()];

  List<_AdminDestination> _destinations() => [
    _AdminDestination(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded, label: 'admin.nav_dashboard'.tr()),
    _AdminDestination(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2_rounded, label: 'admin.nav_products'.tr()),
    _AdminDestination(icon: Icons.category_outlined, selectedIcon: Icons.category_rounded, label: 'admin.nav_categories'.tr()),
    _AdminDestination(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long_rounded, label: 'admin.nav_orders'.tr()),
  ];

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations();
    return ResponsiveBuilder(
      mobile: (context) => _MobileAdminShell(
        selectedIndex: _selectedIndex,
        onSelect: _select,
        destinations: destinations,
        pages: _pages,
      ),
      desktop: (context) => _DesktopAdminShell(
        selectedIndex: _selectedIndex,
        onSelect: _select,
        destinations: destinations,
        pages: _pages,
      ),
    );
  }
}

class _AdminDestination {
  const _AdminDestination({required this.icon, required this.selectedIcon, required this.label});

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _MobileAdminShell extends StatelessWidget {
  const _MobileAdminShell({
    required this.selectedIndex,
    required this.onSelect,
    required this.destinations,
    required this.pages,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<_AdminDestination> destinations;
  final List<Widget> pages;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AdminHeader(),
      body: SafeArea(top: false, child: IndexedStack(index: selectedIndex, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelect,
        destinations: [
          for (final d in destinations) NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
        ],
      ),
    );
  }
}

class _DesktopAdminShell extends StatelessWidget {
  const _DesktopAdminShell({
    required this.selectedIndex,
    required this.onSelect,
    required this.destinations,
    required this.pages,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<_AdminDestination> destinations;
  final List<Widget> pages;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AdminHeader(),
      body: SafeArea(
        top: false,
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              backgroundColor: AppColors.surface,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label)),
              ],
            ),
            VerticalDivider(width: 1, color: AppColors.textSecondary.withValues(alpha: 0.15)),
            Expanded(child: IndexedStack(index: selectedIndex, children: pages)),
          ],
        ),
      ),
    );
  }
}
