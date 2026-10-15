import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Changing the theme's body font (what a language switch does) must change the
/// font of the text in the same frame — not ~100 ms later, halfway through
/// Flutter's 200 ms theme animation, which showed the new language's text in
/// the old font for a moment.
void main() {
  Widget app(String family, {required Duration themeAnimation}) => MaterialApp(
    theme: ThemeData(textTheme: const TextTheme(bodyMedium: TextStyle()).apply(fontFamily: family)),
    themeAnimationDuration: themeAnimation,
    home: Builder(builder: (context) => Text('x', style: Theme.of(context).textTheme.bodyMedium)),
  );

  String? fontOfText(WidgetTester tester) => tester.widget<RichText>(find.byType(RichText).first).text.style?.fontFamily;

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
}
