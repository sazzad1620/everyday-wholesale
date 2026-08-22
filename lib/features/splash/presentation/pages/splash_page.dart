import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/route_paths.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SplashBloc>()..add(const SplashStarted()),
      child: BlocListener<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is SplashReady) {
            context.go(RoutePaths.home);
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
