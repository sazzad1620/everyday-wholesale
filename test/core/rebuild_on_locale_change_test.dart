import 'package:easy_localization/easy_localization.dart';
import 'package:everyday_wholesale/core/localization/app_locales.dart';
import 'package:everyday_wholesale/core/localization/rebuild_on_locale_change.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts how many times it has been created — a language switch must not
/// recreate it (that is what used to reload everything and flash black).
int _created = 0;

class _Screen extends StatefulWidget {
  const _Screen();

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _created++;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // A `const` child reading its text with a context-free `.tr()`: the
          // case Flutter would normally never rebuild on a language change.
          const _ConstLabel(),
          TextField(controller: controller),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _SecondPage())),
            child: const Text('open'),
          ),
        ],
      ),
    );
  }
}

class _ConstLabel extends StatelessWidget {
  const _ConstLabel();

  @override
  Widget build(BuildContext context) => Text('language.title'.tr());
}

class _SecondPage extends StatelessWidget {
  const _SecondPage();

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('drawer.category_title'.tr())));
}

/// One test with one mounted app: easy_localization's translation load only
/// completes in the first test's fake-async zone.
void main() {
  testWidgets('a language switch refreshes all text in place and keeps state, routes and input', (tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: AppLocales.supported,
        path: 'assets/translations',
        fallbackLocale: AppLocales.fallback,
        startLocale: AppLocales.en,
        useOnlyLangCode: true,
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            builder: (context, child) => RebuildOnLocaleChange(child: child!),
            home: const _Screen(),
          ),
        ),
      ),
    );
    for (var i = 0; i < 100 && find.text('Language').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(find.text('Language'), findsOneWidget);
    expect(_created, 1);

    // Give the screen some state of its own: typed text and a second page.
    await tester.enterText(find.byType(TextField), 'half-typed');
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Categories'), findsOneWidget);

    // Switch to Japanese.
    await tester.element(find.byType(Scaffold).last).setLocale(AppLocales.ja);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();

    // The page on screen is redrawn in Japanese — in that very frame...
    expect(find.text('Categories'), findsNothing);
    expect(find.text('カテゴリー'), findsOneWidget);

    // ...and nothing was thrown away: still on the second page, the first
    // screen was not recreated, and what was typed is still there.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('言語'), findsOneWidget, reason: 'the const label under the first page was refreshed too');
    expect(find.text('Language'), findsNothing);
    expect(_created, 1, reason: 'the screen must not be recreated by a language switch');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'half-typed');

    // And back again.
    await tester.element(find.byType(Scaffold).last).setLocale(AppLocales.en);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(find.text('Language'), findsOneWidget);
    expect(_created, 1);
  });
}
