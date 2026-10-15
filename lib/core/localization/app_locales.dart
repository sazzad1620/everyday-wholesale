import 'package:flutter/widgets.dart';

import 'japanese_font.dart';

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

  /// Bundled English body font (see `pubspec.yaml`), the same on Android,
  /// iOS and web instead of each platform's own default.
  static const String latinFontFamily = 'PlusJakartaSans';

  /// The body font — the **same for every language**.
  ///
  /// Plus Jakarta Sans first, with Noto Sans JP (see [JapaneseFont], loaded when
  /// Japanese is in use) as its fallback: the Latin font has no kana/kanji, so
  /// those come from Noto Sans JP, and English letters and digits look the same
  /// in both languages.
  ///
  /// It must not depend on [locale]. Material widgets (every Scaffold and Card)
  /// animate a change of their inherited text style over 200 ms, and a font
  /// family cannot be blended — it flips at the halfway point, so the new
  /// language's text was drawn in the old language's font for ~100 ms before
  /// jumping. With one constant font setting a language switch changes only the
  /// text, never the font. (Android/iOS and web alike.)
  static TextStyle? bodyFontFor(Locale locale) =>
      const TextStyle(fontFamily: latinFontFamily, fontFamilyFallback: [JapaneseFont.family]);
}
