import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../auth/presentation/bloc/account_bloc.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  /// Waits for whichever finishes last: [SplashBloc]'s own minimum-display
  /// timer, and Firebase Auth resolving whether a session is already
  /// persisted ([AccountState.isInitializing]). Without this second wait, a
  /// cold-started app would route before knowing whether the restored
  /// session belongs to an admin — the exact gap that let a restarted admin
  /// land on the customer home page instead of the admin panel (they'd only
  /// reach it again by signing out and back in, since the sign-in dialog is
  /// the only other place with this same admin check). Bounded by a timeout
  /// so a stalled/erroring auth check can never hang the splash screen
  /// forever — worst case, it just falls through to the customer home page,
  /// same as today's behavior.
  Future<void> _waitForAccountResolution() {
    final accountBloc = getIt<AccountBloc>();
    if (!accountBloc.state.isInitializing) return Future.value();
    return accountBloc.stream
        .firstWhere((state) => !state.isInitializing)
        .timeout(const Duration(seconds: 5), onTimeout: () => accountBloc.state);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SplashBloc>()..add(const SplashStarted()),
      child: BlocListener<SplashBloc, SplashState>(
        listener: (context, state) async {
          if (state is SplashReady) {
            await _waitForAccountResolution();
            if (!context.mounted) return;
            final isAdmin = getIt<AccountBloc>().state.user?.isAdmin ?? false;
            context.go(isAdmin ? RoutePaths.admin : RoutePaths.home);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: Center(
            child: Image.asset(AssetPaths.logo, width: 180),
          ),
        ),
      ),
    );
  }
}
