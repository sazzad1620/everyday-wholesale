import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/loaders/app_loader.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../account/presentation/widgets/account_sheet.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../utils/category_navigation.dart';
import '../widgets/category_grid.dart';
import '../widgets/home_promo_carousel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeBloc>()..add(const HomeStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            AppHeader(
              onMenuTap: () => Scaffold.of(context).openDrawer(),
              onAccountTap: () => openAccountMenu(context),
            ),
            Expanded(
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) => _HomeBody(state: state),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    if (state is HomeLoading || state is HomeInitial) {
      return const Center(child: AppLoader());
    }

    if (state is HomeError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.sm),
              Text('common.generic_error'.tr(), style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.read<HomeBloc>().add(const HomeStarted()),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    final loaded = state as HomeLoaded;

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
      children: [
        HomePromoCarousel(banners: loaded.promoBanners),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('home.explore_categories'.tr(), style: AppTextStyles.title),
        ),
        const SizedBox(height: AppSpacing.sm),
        CategoryGrid(
          categories: loaded.categories,
          onCategoryTap: (category) => navigateToCategory(context, category),
        ),
      ],
    );
  }
}
