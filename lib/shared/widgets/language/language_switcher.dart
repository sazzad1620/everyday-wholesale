import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/di/injection_container.dart';
import '../../../core/localization/app_locales.dart';
import '../../../core/localization/japanese_font.dart';
import '../../../features/auth/presentation/bloc/account_bloc.dart';
import '../../../features/auth/presentation/bloc/account_event.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Switches the app language. easy_localization persists the choice on the
/// device; a signed-in user additionally gets it saved on their profile
/// (`users/{uid}.preferredLocale`) so it follows them to other devices —
/// see `EverydayWholesaleApp` for where that's applied at sign-in. Every
/// entry point (header, drawer tiles, account row) funnels through here.
Future<void> setAppLocale(BuildContext context, Locale locale) async {
  if (context.locale == locale) return;
  // On a phone the Japanese font is a file inside the app, so load it *first*:
  // the switch then happens in one go, instead of the new text appearing in a
  // stand-in font and re-shaping a moment later. (On the web it is a download,
  // so the switch isn't held up for it.)
  if (!kIsWeb && locale.languageCode == AppLocales.ja.languageCode) {
    await JapaneseFont.ensureLoaded();
    if (!context.mounted) return;
  }
  await context.setLocale(locale);
  getIt<AccountBloc>().add(AccountPreferredLocaleUpdateRequested(locale.languageCode));
}

/// Compact `English | 日本語` segmented switch.
///
/// Animates the way the Sokrio app's pill toggle does: tapping the other
/// language fades a green fill into that half while it grows a little wider and
/// the half you left shrinks and loses its fill — one smooth morph (260 ms,
/// ease-out) on a soft floating shadow, with the label colour fading along
/// with it. The track itself never changes size, so nothing around it
/// shifts. Used in the tablet/desktop [AppHeader] and inline in
/// [LanguageMenuTile] on phone.
///
/// Kept deliberately small (a 30 px track, 12 px labels) so it reads as a
/// quiet setting rather than a primary control. Whichever language is active is
/// the wider half, so neither is favoured; a label that doesn't fit (very large
/// accessibility text) shrinks instead of wrapping. The touch target is taller
/// than the visible track, and a tap on the active half does nothing.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  static const double _selectedWidth = 64;
  static const double _unselectedWidth = 52;
  static const double _segmentHeight = 26;
  static const double _trackPadding = 2;
  static const double _touchPadding = 8; // extra, invisible, above and below
  static const Duration _duration = Duration(milliseconds: 260);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final languages = AppLocales.supported;
    final index = languages.indexWhere((l) => l.languageCode == context.locale.languageCode).clamp(0, languages.length - 1);
    // Constant: one wide half plus the narrow others, so the track never resizes.
    final trackWidth = _selectedWidth + _unselectedWidth * (languages.length - 1) + _trackPadding * 2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // One handler for the whole control: the half that was tapped wins. That
      // also makes the invisible padding above/below tappable.
      onTapUp: (details) {
        final tapped = (details.localPosition.dx / trackWidth * languages.length).floor().clamp(0, languages.length - 1);
        if (tapped == index) return;
        HapticFeedback.selectionClick();
        setAppLocale(context, languages[tapped]);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _touchPadding),
          child: Container(
            width: trackWidth,
            padding: const EdgeInsets.all(_trackPadding),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(999),
              // Soft, low glow under the track so it floats a little.
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(
              children: [
                for (var i = 0; i < languages.length; i++)
                  _Segment(
                    text: AppLocales.nativeLabel(languages[i]),
                    selected: i == index,
                    onTap: () => setAppLocale(context, languages[i]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.text, required this.selected, required this.onTap});

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Same-length shadow lists (the idle one fully transparent) so Flutter can
    // fade the glow in and out instead of snapping it.
    final glow = AppColors.primary.withValues(alpha: selected ? 0.28 : 0);
    return Semantics(
      button: true,
      selected: selected,
      label: text,
      onTap: onTap,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: LanguageToggle._duration,
        curve: LanguageToggle._curve,
        width: selected ? LanguageToggle._selectedWidth : LanguageToggle._unselectedWidth,
        height: LanguageToggle._segmentHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.primary.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: glow, blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedDefaultTextStyle(
            duration: LanguageToggle._duration,
            curve: LanguageToggle._curve,
            maxLines: 1,
            softWrap: false,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            child: Text(text),
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
