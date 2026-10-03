import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/coming_soon_view.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../bloc/offer_badge_bloc.dart';
import '../bloc/offer_list_bloc.dart';
import '../bloc/offer_list_event.dart';
import '../bloc/offer_list_state.dart';
import '../widgets/offer_card.dart';

/// Public customer-facing list of current offers — readable signed-out and
/// by direct URL (web), same as the support page. Pushed on the root
/// navigator, outside the shell.
class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        // Opening the page counts as seeing everything: clears the bell's dot.
        getIt<OfferBadgeBloc>().add(const OfferBadgeSeen());
        return getIt<OfferListBloc>()..add(const OfferListRequested());
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              AppHeader(
                showSearchBar: false,
                showBackButton: true,
                // A direct/reloaded /offers URL has nothing to pop back to.
                onMenuTap: () => context.canPop() ? context.pop() : context.go(RoutePaths.home),
                onAccountTap: () => openAccountMenu(context),
              ),
              const Expanded(child: _OffersBody()),
            ],
          ),
        ),
      ),
    );
  }
}

class _OffersBody extends StatelessWidget {
  const _OffersBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfferListBloc, OfferListState>(
      builder: (context, state) {
        if (state.isLoading) return const Center(child: CircularProgressIndicator());
        if (state.errorMessage != null && state.offers.isEmpty) {
          return ComingSoonView(
            icon: Icons.error_outline_rounded,
            title: 'offers.error_title'.tr(),
            message: state.errorMessage!.tr(),
          );
        }
        if (state.offers.isEmpty) {
          return ComingSoonView(
            icon: Icons.local_offer_outlined,
            title: 'offers.empty_title'.tr(),
            message: 'offers.empty_message'.tr(),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            context.read<OfferListBloc>().add(const OfferListRequested());
            // Offers that arrived while the page was open are seen too.
            getIt<OfferBadgeBloc>().add(const OfferBadgeSeen());
          },
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md) +
                    EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
                itemCount: state.offers.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  if (index == 0) return Text('offers.title'.tr(), style: AppTextStyles.headline);
                  return OfferCard(offer: state.offers[index - 1]);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
