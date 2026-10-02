import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/coming_soon_view.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../../shared/widgets/navigation/desktop_body.dart';
import '../../../../shared/widgets/product_grid.dart';
import '../../../../shared/widgets/responsive_content_container.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../bloc/wishlist_bloc.dart';
import '../bloc/wishlist_state.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        // Bottom handled by the scroll view's padding instead, so content can
        // run behind the floating bottom nav (StandaloneShellScaffold.extendBody).
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              onMenuTap: () => Scaffold.of(context).openDrawer(),
              onAccountTap: () => openAccountMenu(context),
            ),
            Expanded(
              child: DesktopBody(
                child: BlocBuilder<WishlistBloc, WishlistState>(
                  bloc: getIt<WishlistBloc>(),
                  builder: (context, state) => _WishlistBody(state: state),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistBody extends StatelessWidget {
  const _WishlistBody({required this.state});

  final WishlistState state;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return ComingSoonView(
        icon: Icons.favorite_border_rounded,
        title: 'wishlist.empty_title'.tr(),
        message: 'wishlist.empty_message'.tr(),
      );
    }

    return ResponsiveContentContainer(
      child: ProductGrid(
        products: state.items,
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
        // Inside the scroll view: the last row clears the floating bottom nav
        // (+ system bar) while content still scrolls behind it.
        gridPadding: EdgeInsets.only(bottom: AppSpacing.md + MediaQuery.paddingOf(context).bottom),
        onTap: (product) => context.push(
          RoutePaths.productDetail(product.categoryId, product.id),
        ),
      ),
    );
  }
}
