import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../core/utils/responsive/responsive_builder.dart';
import '../../../auth/presentation/bloc/account_bloc.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DashboardBloc>()..add(const DashboardStatsRequested()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final user = getIt<AccountBloc>().state.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.dashboard_greeting'.tr(namedArgs: {'name': user?.name ?? ''}),
            style: AppTextStyles.headline,
          ),
          const SizedBox(height: AppSpacing.lg),
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              return switch (state) {
                DashboardInitial() || DashboardInProgress() => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                DashboardFailure(:final message) => Text(
                  message,
                  style: AppTextStyles.body.copyWith(color: AppColors.error),
                ),
                DashboardLoaded(:final stats) => _StatsGrid(stats: stats),
              };
            },
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final DashboardStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (context) => _grid(crossAxisCount: 2),
      desktop: (context) => _grid(crossAxisCount: 4),
    );
  }

  Widget _grid({required int crossAxisCount}) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.4,
      children: [
        _StatCard(icon: Icons.inventory_2_rounded, label: 'admin.stat_products'.tr(), value: stats.totalProducts),
        _StatCard(icon: Icons.category_rounded, label: 'admin.stat_categories'.tr(), value: stats.totalCategories),
        _StatCard(icon: Icons.receipt_long_rounded, label: 'admin.stat_orders'.tr(), value: stats.totalOrders),
        _StatCard(
          icon: Icons.pending_actions_rounded,
          label: 'admin.stat_pending_orders'.tr(),
          value: stats.pendingOrders,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(height: AppSpacing.sm),
          Text('$value', style: AppTextStyles.headline),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
