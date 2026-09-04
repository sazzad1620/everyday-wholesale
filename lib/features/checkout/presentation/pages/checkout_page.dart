import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../core/utils/responsive/breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/utils/toast.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../auth/presentation/bloc/account_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../payment/domain/entities/payment_confirmation_result.dart';
import '../../../payment/presentation/payment_confirmation.dart';
import '../bloc/checkout_bloc.dart';
import '../bloc/checkout_event.dart';
import '../bloc/checkout_state.dart';
import '../widgets/delivery_address_card.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/payment_method_sheet.dart';
import 'order_confirmation_page.dart';

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

class _CheckoutView extends StatefulWidget {
  const _CheckoutView();

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  PaymentMethodOption? _paymentMethod;

  Future<void> _pickPaymentMethod(BuildContext context) async {
    final picked = await showPaymentMethodSheet(
      context,
      selected: _paymentMethod,
    );
    if (picked != null) setState(() => _paymentMethod = picked);
  }

  void _placeOrder(BuildContext context) {
    final address = getIt<AccountBloc>().state.user?.address;
    if (address == null) {
      AppToast.show(
        context,
        'checkout.address_required'.tr(),
        type: ToastType.error,
      );
      return;
    }

    final paymentMethod = _paymentMethod;
    if (paymentMethod == null) {
      AppToast.show(
        context,
        'checkout.payment_method_required'.tr(),
        type: ToastType.error,
      );
      return;
    }

    context.read<CheckoutBloc>().add(
      CheckoutOrderPlaceRequested(
        paymentMethod: paymentMethod.label(),
        requiresCardPayment: paymentMethod == PaymentMethodOption.card,
        addressLine: address.formattedLine,
        addressPhone: address.phoneNumber,
        addressReceiverName: address.receiverName,
      ),
    );
  }

  Future<void> _confirmPendingPayment(
    BuildContext context,
    String clientSecret,
  ) async {
    final bloc = context.read<CheckoutBloc>();
    final result = await confirmCardPayment(
      context: context,
      clientSecret: clientSecret,
    );
    if (!context.mounted) return;
    switch (result) {
      case PaymentConfirmationSucceeded():
        bloc.add(const CheckoutPaymentConfirmed());
      case PaymentConfirmationCanceled():
        bloc.add(const CheckoutPaymentCanceled());
      case PaymentConfirmationFailed(:final message):
        bloc.add(CheckoutPaymentFailed(message));
    }
  }

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
                listenWhen: (previous, current) {
                  final pendingSecretAppeared =
                      current.pendingPaymentClientSecret != null &&
                      previous.pendingPaymentClientSecret !=
                          current.pendingPaymentClientSecret;
                  final placingFinished =
                      previous.isPlacingOrder && !current.isPlacingOrder;
                  return pendingSecretAppeared || placingFinished;
                },
                listener: (context, state) async {
                  if (state.pendingPaymentClientSecret != null &&
                      !state.paymentConfirmed) {
                    await _confirmPendingPayment(
                      context,
                      state.pendingPaymentClientSecret!,
                    );
                    return;
                  }
                  if (state.errorMessage != null) {
                    AppToast.show(
                      context,
                      state.errorMessage!,
                      type: ToastType.error,
                    );
                  } else if (state.paymentConfirmed &&
                      state.placedOrder != null) {
                    context.go(
                      RoutePaths.orderConfirmation,
                      extra: OrderConfirmationArgs(
                        order: state.placedOrder!,
                        isCardOrder: _paymentMethod == PaymentMethodOption.card,
                      ),
                    );
                  }
                },
                builder: (context, checkoutState) {
                  return BlocBuilder<CartBloc, CartState>(
                    bloc: getIt<CartBloc>(),
                    builder: (context, cartState) {
                      final isWide =
                          MediaQuery.sizeOf(context).width >=
                          AppBreakpoints.mobile;

                      final placeOrderButton = PrimaryButton(
                        label: 'checkout.place_order'.tr(),
                        isLoading: checkoutState.isPlacingOrder,
                        onTap: () => _placeOrder(context),
                      );

                      // Desktop: address/payment method scroll on the left,
                      // the order recap + place-order button stay put on
                      // the right instead of scrolling below a long address
                      // form — phone keeps everything in one stacked list.
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                children: [
                                  const DeliveryAddressCard(),
                                  const SizedBox(height: AppSpacing.sm),
                                  PaymentMethodCard(
                                    selected: _paymentMethod,
                                    onTap: () => _pickPaymentMethod(context),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 360,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  AppSpacing.md,
                                  AppSpacing.md,
                                  AppSpacing.md,
                                ),
                                child: Column(
                                  children: [
                                    OrderSummaryCard(
                                      items: cartState.items,
                                      itemTotal: cartState.itemTotal,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    placeOrderButton,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: [
                          const DeliveryAddressCard(),
                          const SizedBox(height: AppSpacing.sm),
                          OrderSummaryCard(
                            items: cartState.items,
                            itemTotal: cartState.itemTotal,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          PaymentMethodCard(
                            selected: _paymentMethod,
                            onTap: () => _pickPaymentMethod(context),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          placeOrderButton,
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
