import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../auth/presentation/bloc/account_bloc.dart';
import '../../../auth/presentation/bloc/account_event.dart';

/// Placeholder proof-of-concept, not the real admin dashboard (that's
/// roadmap Phase 5 — dashboard, product management, order management).
/// Exists only to verify role-based routing actually works end to end:
/// signing in as a `role: admin` account lands here instead of Home.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = getIt<AccountBloc>().state.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings_rounded, size: 56, color: AppColors.primary),
              const SizedBox(height: AppSpacing.md),
              Text('Welcome, ${user?.name ?? ''}', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Signed in as admin (role check passed).',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Log Out',
                onTap: () {
                  getIt<AccountBloc>().add(const AccountSignOutRequested());
                  context.go(RoutePaths.home);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
