import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/responsive/responsive_builder.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../widgets/admin_menu_drawer.dart';
import 'admin_categories_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_orders_page.dart';
import 'admin_products_page.dart';

/// Root of the admin/manager side. Header is the plain shared [AppHeader]
/// (logo + hamburger + account icon, no search bar) — same look as every
/// customer page, rather than a bespoke admin header. Navigation is a
/// [AdminMenuDrawer] opened from that hamburger on every breakpoint, plus an
/// always-visible `NavigationRail` on tablet/desktop where there's room for
/// both. No bottom `NavigationBar` on mobile anymore — a drawer is the
/// standard admin-panel pattern (Shopify, Firebase console, etc.), and it
/// unifies the interaction model with the customer side's own
/// hamburger-opens-drawer navigation instead of running two different ones.
class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  static const _pages = [AdminDashboardPage(), AdminProductsPage(), AdminCategoriesPage(), AdminOrdersPage()];

  List<AdminDestination> _destinations() => [
    AdminDestination(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded, label: 'admin.nav_dashboard'.tr()),
    AdminDestination(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2_rounded, label: 'admin.nav_products'.tr()),
    AdminDestination(icon: Icons.category_outlined, selectedIcon: Icons.category_rounded, label: 'admin.nav_categories'.tr()),
    AdminDestination(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long_rounded, label: 'admin.nav_orders'.tr()),
  ];

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: AdminMenuDrawer(selectedIndex: _selectedIndex, onSelect: _select, destinations: destinations),
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              showSearchBar: false,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              onAccountTap: () => openAccountMenu(context),
            ),
            Expanded(
              child: ResponsiveBuilder(
                mobile: (context) => IndexedStack(index: _selectedIndex, children: _pages),
                desktop: (context) => _DesktopAdminBody(
                  selectedIndex: _selectedIndex,
                  onSelect: _select,
                  destinations: destinations,
                  pages: _pages,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tablet/desktop keeps an always-visible `NavigationRail` alongside the
/// drawer (there's room for both, and a persistent rail is the expected
/// desktop-admin pattern) — the drawer just becomes a second, optional way
/// in on wide screens rather than mobile's only way.
class _DesktopAdminBody extends StatelessWidget {
  const _DesktopAdminBody({
    required this.selectedIndex,
    required this.onSelect,
    required this.destinations,
    required this.pages,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<AdminDestination> destinations;
  final List<Widget> pages;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
