import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/utils/toast.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../bloc/checkout_bloc.dart';
import '../bloc/checkout_event.dart';
import '../bloc/checkout_state.dart';
import '../widgets/delivery_address_card.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/payment_method_card.dart';

/// Pushed outside the bottom-nav shell (see `app_router.dart`'s root
/// `navigatorKey`/`parentNavigatorKey`) — checkout is a focused, full-screen
/// flow, so it drops the drawer/bottom-nav chrome, but still gets the usual
/// [AppHeader] (back arrow instead of the hamburger, same as the account and
/// order-history pages) so the branding stays consistent.
///
/// Only reachable with items in the cart, which itself requires being
/// signed in (see `product_detail_content.dart`'s add-to-cart guard) — so
/// "Place Order" never needs its own separate sign-in check.
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CheckoutBloc>(),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView();

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
              child: BlocConsumer<CheckoutBloc, CheckoutState>(
                listenWhen: (previous, current) => previous.isPlacingOrder && !current.isPlacingOrder,
                listener: (context, state) {
                  if (state.errorMessage != null) {
                    AppToast.show(context, state.errorMessage!, type: ToastType.error);
                  } else if (state.placedOrder != null) {
                    context.go(RoutePaths.orderConfirmation, extra: state.placedOrder);
                  }
                },
                builder: (context, checkoutState) {
                  return BlocBuilder<CartBloc, CartState>(
                    bloc: getIt<CartBloc>(),
                    builder: (context, cartState) {
                      return ListView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: [
                          const DeliveryAddressCard(),
                          const SizedBox(height: AppSpacing.sm),
                          OrderSummaryCard(items: cartState.items, itemTotal: cartState.itemTotal),
                          const SizedBox(height: AppSpacing.sm),
                          const PaymentMethodCard(),
                          const SizedBox(height: AppSpacing.lg),
                          PrimaryButton(
                            label: 'checkout.place_order'.tr(),
                            isLoading: checkoutState.isPlacingOrder,
                            onTap: () => context.read<CheckoutBloc>().add(
                              CheckoutOrderPlaceRequested(
                                // Payment/address are still the same
                                // placeholder values shown on this card —
                                // real ones land once Stripe (Phase 6) and
                                // address management (Phase 4 follow-up)
                                // are built. The order itself is real.
                                paymentMethod: 'checkout.mock_payment_method'.tr(),
                                addressLine: 'checkout.mock_address_line'.tr(),
                                addressPhone: 'checkout.mock_address_phone'.tr(),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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
