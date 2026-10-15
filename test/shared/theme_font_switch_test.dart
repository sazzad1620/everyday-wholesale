import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyday_wholesale/core/localization/app_locales.dart';
import 'package:everyday_wholesale/shared/theme/app_theme.dart';

/// Changing the theme's body font (what a language switch does) must change the
/// font of the text in the same frame — not ~100 ms later, halfway through
/// Flutter's 200 ms theme animation, which showed the new language's text in
/// the old font for a moment.
void main() {
  Widget app(String family, {required Duration themeAnimation}) => MaterialApp(
    theme: ThemeData(
      textTheme: const TextTheme(bodyMedium: TextStyle()).apply(fontFamily: family),
    ),
    themeAnimationDuration: themeAnimation,
    home: Builder(builder: (context) => Text('x', style: Theme.of(context).textTheme.bodyMedium)),
  );

  String? fontOfText(WidgetTester tester) =>
      tester.widget<RichText>(find.byType(RichText).first).text.style?.fontFamily;

  testWidgets('with no theme animation the new font is used at once', (tester) async {
    await tester.pumpWidget(app('NotoSansJP', themeAnimation: Duration.zero));
    await tester.pumpWidget(app('PlusJakartaSans', themeAnimation: Duration.zero));
    await tester.pump(const Duration(milliseconds: 20));
    expect(fontOfText(tester), 'PlusJakartaSans');
  });

  testWidgets('with Flutter\'s default animation the old font lingers (the bug this prevents)', (tester) async {
    await tester.pumpWidget(app('NotoSansJP', themeAnimation: kThemeAnimationDuration));
    await tester.pumpWidget(app('PlusJakartaSans', themeAnimation: kThemeAnimationDuration));
    await tester.pump(const Duration(milliseconds: 20));
    expect(fontOfText(tester), 'NotoSansJP');
  });

  // The real fix: Material widgets (any Scaffold/Card) animate their inherited
  // text style over 200 ms regardless of themeAnimationDuration, and a font
  // family flips only at the halfway point. So the body font must be identical
  // in every language — a switch then changes the text only.
  test('the body font is the same for every language', () {
    final en = AppLocales.bodyFontFor(AppLocales.en)!;
    final ja = AppLocales.bodyFontFor(AppLocales.ja)!;
    expect(ja.fontFamily, en.fontFamily);
    expect(ja.fontFamilyFallback, en.fontFamilyFallback);
    expect(en.fontFamily, AppLocales.latinFontFamily);
    expect(en.fontFamilyFallback, contains('NotoSansJP'), reason: 'kana/kanji come from Noto Sans JP');
  });

  testWidgets('plain text under a Scaffold keeps one font across a language switch', (tester) async {
    Widget app(Locale locale) => MaterialApp(
      theme: AppTheme.light(bodyFont: AppLocales.bodyFontFor(locale)),
      themeAnimationDuration: Duration.zero,
      locale: locale,
      home: const Scaffold(body: Text('x')),
    );
    await tester.pumpWidget(app(AppLocales.ja));
    await tester.pumpWidget(app(AppLocales.en));
    for (final ms in [0, 20, 100, 220]) {
      await tester.pump(Duration(milliseconds: ms));
      expect(fontOfText(tester), AppLocales.latinFontFamily, reason: 'at +$ms ms');
    }
  });
}
