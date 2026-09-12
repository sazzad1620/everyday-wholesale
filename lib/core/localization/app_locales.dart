import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single source of truth for which languages the app ships — `bootstrap.dart`
/// registers these with `EasyLocalization`, and the language switcher widgets
/// list them. Add a locale here (plus its `assets/translations/<code>.json`)
/// to add a language.
abstract final class AppLocales {
  static const Locale en = Locale('en');
  static const Locale ja = Locale('ja');

  static const List<Locale> supported = [en, ja];

  /// Every visitor starts in English regardless of device language (client
  /// decision); `EasyLocalization` then remembers whatever they switch to.
  static const Locale start = en;
  static const Locale fallback = en;

  /// Each language's name written in *that* language, so the switcher reads
  /// naturally to a user who can't read the currently active one.
  static String nativeLabel(Locale locale) => switch (locale.languageCode) {
    'ja' => '日本語',
    _ => 'English',
  };

  /// Compact label for the header toggle (`EN | 日本語`).
  static String shortLabel(Locale locale) => switch (locale.languageCode) {
    'ja' => '日本語',
    _ => 'EN',
  };

  /// The body font for [locale], or `null` to keep the platform default.
  ///
  /// English stays on the platform default (Roboto / SF / Flutter web's
  /// Roboto) exactly as before. Japanese switches the whole text theme to
  /// Noto Sans JP so kana/kanji render in one consistent face on every
  /// platform — without this, web mixes the engine's CJK fallback with
  /// Roboto, and desktop browsers can show mismatched weights.
  static TextStyle? bodyFontFor(Locale locale) => switch (locale.languageCode) {
    'ja' => GoogleFonts.notoSansJp(),
    _ => null,
  };
}
