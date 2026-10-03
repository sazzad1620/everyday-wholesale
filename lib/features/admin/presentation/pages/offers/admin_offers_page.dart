import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/di/injection_container.dart';
import '../../../../../config/routes/route_paths.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_spacing.dart';
import '../../../../../shared/theme/app_text_styles.dart';
import '../../../../../shared/utils/toast.dart';
import '../../../../../shared/widgets/coming_soon_view.dart';
import '../../../../../shared/widgets/dialogs/confirm_dialog.dart';
import '../../../../offer/presentation/bloc/offer_list_bloc.dart';
import '../../../../offer/presentation/bloc/offer_list_event.dart';
import '../../../../offer/presentation/bloc/offer_list_state.dart';
import '../../../../offer/presentation/widgets/offer_card.dart';

/// Offers management tab — everything sent so far (expired ones included,
/// flagged), with a "New offer" action that opens the form and a delete per
/// offer.
class AdminOffersPage extends StatelessWidget {
  const AdminOffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OfferListBloc>()..add(const OfferListRequested(includeExpired: true)),
      child: const _OfferListView(),
    );
  }
}

class _OfferListView extends StatelessWidget {
  const _OfferListView();

  Future<void> _openForm(BuildContext context) async {
    final bloc = context.read<OfferListBloc>();
    final created = await context.push<bool>(RoutePaths.adminOfferForm);
    if (created == true) bloc.add(const OfferListRequested(includeExpired: true));
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final bloc = context.read<OfferListBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.delete_offer_title'.tr(),
      message: 'admin.delete_offer_message'.tr(),
      confirmLabel: 'admin.delete'.tr(),
      cancelLabel: 'admin.cancel'.tr(),
    );
    if (confirmed) bloc.add(OfferDeleteRequested(id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OfferListBloc, OfferListState>(
      listenWhen: (previous, current) => current.errorMessage != null && previous.errorMessage != current.errorMessage,
      listener: (context, state) => AppToast.show(context, state.errorMessage!.tr(), type: ToastType.error),
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(child: Text('admin.nav_offers'.tr(), style: AppTextStyles.headline)),
                  Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openForm(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'admin.add_offer'.tr(),
                              style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3, child: state.isBusy ? const LinearProgressIndicator() : null),
            Expanded(child: _buildBody(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, OfferListState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.offers.isEmpty) {
      return ComingSoonView(
        icon: Icons.local_offer_outlined,
        title: 'admin.offers_empty_title'.tr(),
        message: 'admin.offers_empty_message'.tr(),
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: state.offers.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final offer = state.offers[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OfferCard(
                  offer: offer,
                  trailing: IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    onPressed: state.isBusy ? null : () => _confirmDelete(context, offer.id),
                  ),
                ),
                if (offer.expiresAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.xs),
                    child: Text(
                      (offer.isExpired ? 'admin.offer_expired_on' : 'admin.offer_expires_on').tr(
                        namedArgs: {'date': formatShortDate(context, offer.expiresAt!)},
                      ),
                      style: AppTextStyles.caption.copyWith(
                        color: offer.isExpired ? AppColors.error : AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
