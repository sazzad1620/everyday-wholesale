import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../widgets/delivery_address_card.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/payment_method_card.dart';

/// Pushed outside the bottom-nav shell (see `app_router.dart`'s root
/// `navigatorKey`/`parentNavigatorKey`) — checkout is a focused, full-screen
/// flow, so it drops the usual [AppHeader]/bottom-nav chrome in favor of a
/// plain themed [AppBar] (same green/white treatment [WishlistPage] uses).
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('checkout.title'.tr())),
      body: BlocBuilder<CartBloc, CartState>(
        bloc: getIt<CartBloc>(),
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const DeliveryAddressCard(),
              const SizedBox(height: AppSpacing.sm),
              OrderSummaryCard(items: state.items, itemTotal: state.itemTotal),
              const SizedBox(height: AppSpacing.sm),
              const PaymentMethodCard(),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'checkout.place_order'.tr(),
                onTap: () {
                  getIt<CartBloc>().add(const CartCleared());
                  context.go(RoutePaths.orderConfirmation);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
