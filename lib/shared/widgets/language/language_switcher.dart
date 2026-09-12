import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_locales.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Switches the app language and lets easy_localization persist the choice.
/// Every entry point (header toggle, drawer tile, account row) funnels
/// through here so there's one place to hook extra work later — e.g.
/// writing `preferredLocale` to the signed-in user's doc.
Future<void> setAppLocale(BuildContext context, Locale locale) {
  if (context.locale == locale) return Future.value();
  return context.setLocale(locale);
}

/// Compact `EN | 日本語` segmented toggle for the tablet/desktop [AppHeader]
/// row — the standard placement on Japanese e-commerce sites, and reachable
/// by signed-out visitors, who have no account page to find it in.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.locale;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, locale) in AppLocales.supported.indexed) ...[
            if (i > 0)
              Container(width: 1, height: 18, color: AppColors.textSecondary.withValues(alpha: 0.3)),
            _ToggleSegment(
              label: AppLocales.shortLabel(locale),
              selected: locale == current,
              onTap: () => setAppLocale(context, locale),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// "Language · English ›" list row for phone-width menus — [MainMenuDrawer],
/// [AdminMenuDrawer] and the account page — where the header is too tight
/// for [LanguageToggle]. Tapping opens [showLanguagePicker].
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocales.nativeLabel(context.locale),
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
      onTap: () => showLanguagePicker(context),
    );
  }
}

/// Bottom sheet listing every supported language in its own script, with a
/// check on the active one. Picking a language applies it immediately and
/// closes the sheet.
Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (sheetContext) {
      // Read from the *caller's* context: the sheet is pushed on the root
      // navigator, whose context sits above EasyLocalization's rebuild scope.
      final current = context.locale;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
              child: Text('language.choose'.tr(), style: AppTextStyles.title),
            ),
            for (final locale in AppLocales.supported)
              ListTile(
                title: Text(AppLocales.nativeLabel(locale), style: AppTextStyles.body),
                trailing: locale == current ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setAppLocale(context, locale);
                },
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    },
  );
}
