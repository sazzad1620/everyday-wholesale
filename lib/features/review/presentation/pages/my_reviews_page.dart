import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/utils/toast.dart';
import '../../../../shared/widgets/coming_soon_view.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../account/presentation/widgets/desktop_account_body.dart';
import '../../../account/presentation/widgets/desktop_account_nav.dart';
import '../../../auth/presentation/bloc/account_bloc.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/entities/reviewable_item_entity.dart';
import '../bloc/my_reviews_bloc.dart';
import '../bloc/my_reviews_event.dart';
import '../bloc/my_reviews_state.dart';
import '../widgets/review_history_tile.dart';
import '../widgets/reviewable_item_card.dart';

/// Reached from Account > My Reviews. Two tabs: products from completed
/// orders still waiting for a star rating, and every rating the customer has
/// already submitted.
class MyReviewsPage extends StatelessWidget {
  const MyReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MyReviewsBloc>()..add(const MyReviewsRequested()),
      child: const _MyReviewsView(),
    );
  }
}

class _MyReviewsView extends StatelessWidget {
  const _MyReviewsView();

  void _onRate(BuildContext context, ReviewableItemEntity item, int rating) {
    final reviewerName = getIt<AccountBloc>().state.user?.name ?? '';
    context.read<MyReviewsBloc>().add(
      MyReviewsSubmitRequested(
        orderId: item.orderId,
        productId: item.productId,
        productName: item.productName,
        productImageUrl: item.productImageUrl,
        reviewerName: reviewerName,
        rating: rating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                child: DesktopAccountBody(
                  current: AccountNavItem.myReviews,
                  // TabBar lives inside the content column, not spanning
                  // the full page above the sidebar — same reasoning as
                  // BreadcrumbBar elsewhere (see DesktopBody's doc comment).
                  child: Column(
                    children: [
                      Material(
                        color: AppColors.surface,
                        child: TabBar(
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.primary,
                          tabs: [
                            Tab(text: 'my_reviews.tab_to_be_reviewed'.tr()),
                            Tab(text: 'my_reviews.tab_history'.tr()),
                          ],
                        ),
                      ),
                      Expanded(
                        child: BlocConsumer<MyReviewsBloc, MyReviewsState>(
                          listenWhen: (previous, current) =>
                              previous.submittingKey != null &&
                              current.submittingKey == null &&
                              current.errorMessage != null,
                          listener: (context, state) => AppToast.show(
                            context,
                            state.errorMessage!,
                            type: ToastType.error,
                          ),
                          builder: (context, state) {
                            if (state.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return TabBarView(
                              children: [
                                _ToBeReviewedTab(
                                  state: state,
                                  onRate: (item, rating) =>
                                      _onRate(context, item, rating),
                                ),
                                _HistoryTab(reviews: state.historyReviews),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToBeReviewedTab extends StatelessWidget {
  const _ToBeReviewedTab({required this.state, required this.onRate});

  final MyReviewsState state;
  final void Function(ReviewableItemEntity item, int rating) onRate;

  @override
  Widget build(BuildContext context) {
    if (state.reviewableItems.isEmpty) {
      return ComingSoonView(
        icon: Icons.rate_review_outlined,
        title: 'my_reviews.to_be_reviewed_empty_title'.tr(),
        message: 'my_reviews.to_be_reviewed_empty_message'.tr(),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: state.reviewableItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final item = state.reviewableItems[index];
        final key = '${item.orderId}_${item.productId}';
        return ReviewableItemCard(
          item: item,
          isSubmitting: state.submittingKey == key,
          onRate: (rating) => onRate(item, rating),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.reviews});

  final List<ReviewEntity> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return ComingSoonView(
        icon: Icons.star_outline_rounded,
        title: 'my_reviews.history_empty_title'.tr(),
        message: 'my_reviews.history_empty_message'.tr(),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: reviews.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) =>
          ReviewHistoryTile(review: reviews[index]),
    );
  }
}
