import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../config/di/injection_container.dart';
import '../../../shared/utils/toast.dart';
import '../../../shared/widgets/dialogs/sign_in_dialog.dart';
import '../../auth/presentation/bloc/account_bloc.dart';
import '../../product/domain/entities/product_entity.dart';
import 'bloc/cart_bloc.dart';
import 'bloc/cart_event.dart';

/// The single "Add to Cart" path for every button (product cards, product
/// detail) so they all give the same feedback. Signed out: an error toast
/// and the sign-in dialog — the cart lives in the user's Firestore account,
/// so the add would otherwise fail silently. Returns whether it was added.
///
/// Waits briefly if the saved session is still being restored: on web the
/// home page no longer waits for that at startup, so a signed-in customer
/// could otherwise tap "Add" in the first second and be told to sign in.
Future<bool> addToCart(
  BuildContext context,
  ProductEntity product, {
  int quantity = 1,
  bool showSuccessToast = true,
}) async {
  final accountBloc = getIt<AccountBloc>();
  if (accountBloc.state.isInitializing) {
    await accountBloc.stream
        .firstWhere((state) => !state.isInitializing)
        .timeout(const Duration(seconds: 5), onTimeout: () => accountBloc.state);
  }
  if (!context.mounted) return false;

  if (!accountBloc.state.isLoggedIn) {
    AppToast.show(context, 'cart.sign_in_required'.tr(), type: ToastType.error);
    showSignInDialog(context);
    return false;
  }

  getIt<CartBloc>().add(CartItemAdded(product, quantity));
  if (showSuccessToast) {
    AppToast.show(context, 'product.added_to_cart'.tr(), type: ToastType.success);
  }
  return true;
}
