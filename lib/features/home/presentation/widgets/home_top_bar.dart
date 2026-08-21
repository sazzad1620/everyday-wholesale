import 'package:flutter/material.dart';

import '../../../../core/constants/asset_paths.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.onMenuTap, required this.onAccountTap});

  final VoidCallback onMenuTap;
  final VoidCallback onAccountTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenuTap,
            icon: const Icon(Icons.menu_rounded),
            color: AppColors.textPrimary,
          ),
          Expanded(
            child: Center(
              child: Image.asset(AssetPaths.logo, height: 48, fit: BoxFit.contain),
            ),
          ),
          IconButton(
            onPressed: onAccountTap,
            icon: const Icon(Icons.person_outline_rounded),
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}
