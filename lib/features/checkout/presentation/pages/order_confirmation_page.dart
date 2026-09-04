import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/domain/entities/payment_status.dart';
import '../bloc/order_confirmation_bloc.dart';
import '../bloc/order_confirmation_event.dart';
import '../bloc/order_confirmation_state.dart';

/// Route `extra` for [OrderConfirmationPage] — [isCardOrder] is passed
/// explicitly by the checkout flow rather than inferred from
/// `order.stripePaymentIntentId`, because the in-memory [OrderEntity] held
/// by `CheckoutBloc` is never refreshed with the id the `createPaymentIntent`
/// Cloud Function writes to Firestore, so that field reads `null`
/// client-side for a card order right up until this page's live watch pulls
/// the first real snapshot.
class OrderConfirmationArgs {
  const OrderConfirmationArgs({required this.order, required this.isCardOrder});

  final OrderEntity order;
  final bool isCardOrder;
}

/// Cash orders are already final the moment this page is reached, so they
/// render immediately from [OrderConfirmationArgs.order]. Card orders,
/// though, may still be waiting on the webhook (or the reconciliation
/// safety net) to flip `paymentStatus` — those get wrapped in an
/// [OrderConfirmationBloc] that watches the order live instead of just
/// trusting the client-side payment sheet's "succeeded" callback.
class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({this.args, super.key});

  final OrderConfirmationArgs? args;

  @override
  Widget build(BuildContext context) {
    final initialOrder = args?.order;
    if (initialOrder == null || args?.isCardOrder != true) {
      return _OrderConfirmationView(order: initialOrder, isCardOrder: false);
    }

    return BlocProvider(
      create: (_) => getIt<OrderConfirmationBloc>()..add(OrderConfirmationStarted(initialOrder.id)),
      child: BlocBuilder<OrderConfirmationBloc, OrderConfirmationState>(
        builder: (context, state) =>
            _OrderConfirmationView(order: state.order ?? initialOrder, isCardOrder: true),
      ),
    );
  }
}

class _OrderConfirmationView extends StatelessWidget {
  const _OrderConfirmationView({required this.order, required this.isCardOrder});

  final OrderEntity? order;
  final bool isCardOrder;

  @override
  Widget build(BuildContext context) {
    final isProcessing = isCardOrder && order?.paymentStatus == PaymentStatus.unpaid;
    final isFailed = isCardOrder && order?.paymentStatus == PaymentStatus.failed;

    final IconData icon;
    final Color iconColor;
    final String title;
    final String message;
    if (isFailed) {
      icon = Icons.error_rounded;
      iconColor = AppColors.error;
      title = 'checkout.confirmation_failed_title'.tr();
      message = 'checkout.confirmation_failed_message'.tr();
    } else if (isProcessing) {
      icon = Icons.hourglass_top_rounded;
      iconColor = AppColors.primary;
      title = 'checkout.confirmation_processing_title'.tr();
      message = 'checkout.confirmation_processing_message'.tr();
    } else {
      icon = Icons.check_circle_rounded;
      iconColor = AppColors.primary;
      title = 'checkout.confirmation_title'.tr();
      message = 'checkout.confirmation_message'.tr();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: isProcessing
                    ? SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(strokeWidth: 3, color: iconColor),
                      )
                    : Icon(icon, color: iconColor, size: 56),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: AppTextStyles.headline, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (order != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'checkout.confirmation_order_id'.tr(namedArgs: {'id': order!.id}),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: 'checkout.continue_shopping'.tr(), onTap: () => context.go(RoutePaths.home)),
            ],
          ),
        ),
      ),
    );
  }
}
