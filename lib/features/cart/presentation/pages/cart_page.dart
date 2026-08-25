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
import '../../../../shared/widgets/navigation/breadcrumb_bar.dart';
import '../../../account/presentation/widgets/account_sheet.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../widgets/cart_free_shipping_bar.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/cart_summary_card.dart';
import '../widgets/cart_voucher_card.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            AppHeader(
              onMenuTap: () => Scaffold.of(context).openDrawer(),
              onAccountTap: () => showAccountSheet(context),
            ),
            BreadcrumbBar(items: [BreadcrumbItem(label: 'cart.title'.tr(), onTap: () {}, isCurrent: true)]),
            Expanded(
              child: BlocBuilder<CartBloc, CartState>(
                bloc: getIt<CartBloc>(),
                builder: (context, state) => _CartBody(state: state),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBody extends StatelessWidget {
  const _CartBody({required this.state});

  final CartState state;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return ComingSoonView(
        icon: Icons.shopping_cart_outlined,
        title: 'cart.empty_title'.tr(),
        message: 'cart.empty_message'.tr(),
      );
    }

    final cartBloc = getIt<CartBloc>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        CartFreeShippingBar(itemTotal: state.itemTotal),
        const SizedBox(height: AppSpacing.sm),
        for (final item in state.items) ...[
          CartItemCard(
            item: item,
            onQuantityChanged: (quantity) => cartBloc.add(CartQuantityChanged(item.product.id, quantity)),
            onRemove: () => cartBloc.add(CartItemRemoved(item.product.id)),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        const CartVoucherCard(),
        const SizedBox(height: AppSpacing.sm),
        CartSummaryCard(
          itemTotal: state.itemTotal,
          onCheckout: () => context.push(RoutePaths.checkout),
          onReturnToShopping: () => context.go(RoutePaths.home),
        ),
      ],
    );
  }
}
