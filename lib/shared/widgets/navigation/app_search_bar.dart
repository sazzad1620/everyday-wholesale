import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_input_style.dart';
import '../../theme/app_spacing.dart';
import '../../utils/snack_utils.dart';

/// Lives inside [AppHeader]. Uses [AppInputStyle] — the same flat, ash,
/// borderless treatment every real text field will use later.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        decoration: AppInputStyle.boxDecoration(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppInputStyle.radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppInputStyle.radius),
            onTap: () => showComingSoonSnackBar(context, 'Search'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'home.search_hint'.tr(),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ),
                  const Icon(Icons.mic_none_rounded, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
