import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../widgets/delivery_address_card.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/payment_method_card.dart';

/// Pushed outside the bottom-nav shell (see `app_router.dart`'s root
/// `navigatorKey`/`parentNavigatorKey`) — checkout is a focused, full-screen
/// flow, so it drops the drawer/bottom-nav chrome, but still gets the usual
/// [AppHeader] (back arrow instead of the hamburger, same as the account and
/// order-history pages) so the branding stays consistent.
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              showSearchBar: false,
              showBackButton: true,
              onMenuTap: () => context.pop(),
              onAccountTap: () => openAccountMenu(context),
            ),
            Expanded(
              child: BlocBuilder<CartBloc, CartState>(
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
            ),
          ],
        ),
      ),
    );
  }
}
