import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../config/di/injection_container.dart';
import '../../../core/localization/app_locales.dart';
import '../../../features/auth/presentation/bloc/account_bloc.dart';
import '../../../features/auth/presentation/bloc/account_event.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Switches the app language. easy_localization persists the choice on the
/// device; a signed-in user additionally gets it saved on their profile
/// (`users/{uid}.preferredLocale`) so it follows them to other devices —
/// see `EverydayWholesaleApp` for where that's applied at sign-in. Every
/// entry point (header, drawer tiles, account row) funnels through here.
Future<void> setAppLocale(BuildContext context, Locale locale) async {
  if (context.locale == locale) return;
  await context.setLocale(locale);
  getIt<AccountBloc>().add(AccountPreferredLocaleUpdateRequested(locale.languageCode));
}

/// Pill-shaped `EN | 日本語` segmented toggle — the active language sits in
/// a filled brand-green capsule, the other is plain text on the app's
/// standard input-fill track. One tap switches; no picker step. Used in the
/// tablet/desktop [AppHeader] and inline in [LanguageMenuTile] on phone.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.locale;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final locale in AppLocales.supported)
            _PillSegment(
              label: AppLocales.shortLabel(locale),
              selected: locale == current,
              onTap: () => setAppLocale(context, locale),
            ),
        ],
      ),
    );
  }
}

class _PillSegment extends StatelessWidget {
  const _PillSegment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// "Language" row for phone-width menus — [MainMenuDrawer], [AdminMenuDrawer]
/// and the account page — with the [LanguageToggle] sitting inline on the
/// right, so switching is a single tap right in the row rather than a
/// separate picker.
///
/// [contentPadding] and [labelStyle] let each host match its sibling tiles
/// (the drawers and the account list each indent/weight rows differently).
class LanguageMenuTile extends StatelessWidget {
  const LanguageMenuTile({super.key, this.contentPadding, this.labelStyle});

  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: contentPadding,
      leading: const Icon(Icons.language_rounded, color: AppColors.textSecondary),
      title: Text('language.title'.tr(), style: labelStyle ?? AppTextStyles.body),
      trailing: const LanguageToggle(),
    );
  }
}
