import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../account/presentation/pages/account_page.dart';

/// Shared chrome for simple, static informational pages (About, Privacy
/// Policy, Terms & Conditions, Refund Policy) — a header with a back button
/// and a single scrollable column of sections, capped to a readable width.
/// Mirrors `SupportPage`'s layout so every static page in the app looks the
/// same. Pushed on the root navigator, outside the shell.
class StaticPageScaffold extends StatelessWidget {
  const StaticPageScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

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
              // A direct/reloaded URL (web) has nothing to pop back to.
              onMenuTap: () =>
                  context.canPop() ? context.pop() : context.go(RoutePaths.home),
              onAccountTap: () => openAccountMenu(context),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md) +
                        EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
                    children: [
                      Text(title, style: AppTextStyles.headline),
                      const SizedBox(height: AppSpacing.lg),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled paragraph — the building block of every legal/policy page.
class LegalSection extends StatelessWidget {
  const LegalSection({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
