import 'package:easy_localization/easy_localization.dart';
import 'package:everyday_wholesale/core/localization/app_locales.dart';
import 'package:everyday_wholesale/core/localization/localized_text.dart';
import 'package:everyday_wholesale/features/home/domain/entities/subcategory_entity.dart';
import 'package:everyday_wholesale/features/home/presentation/widgets/home_category_strip.dart';
import 'package:everyday_wholesale/features/home/presentation/widgets/subcategory_chip_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _subcategories = [
  for (var i = 0; i < 9; i++)
    SubcategoryEntity(
      id: 's$i',
      name: LocalizedText(en: 'Sub $i'),
    ),
];

/// The chip row above a category's products: "All" first, tapping selects,
/// the chosen chip is highlighted, and a deep link to a far-away chip
/// scrolls it into view (phone) or wraps everything on screen (wide).
void main() {
  _pitchTests();

  testWidgets('All + one chip per subcategory; selection, taps and scrolling', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 900);
    addTearDown(tester.view.reset);

    final selected = ValueNotifier<String?>('s7'); // opened on a far-away chip
    final taps = <String?>[];

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
            home: Scaffold(
              body: ValueListenableBuilder(
                valueListenable: selected,
                builder: (context, value, _) => SubcategoryChipStrip(
                  subcategories: _subcategories,
                  selectedId: value,
                  onSelected: (id) {
                    taps.add(id);
                    selected.value = id;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Translations load from the asset bundle (real async I/O).
    for (var i = 0; i < 100 && find.byType(CategoryCircleItem).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    bool isSelected(String label) =>
        tester.widget<CategoryCircleItem>(find.widgetWithText(CategoryCircleItem, label)).selected;

    // Phone: a scrolling row; the chip the page opened on is on screen.
    expect(find.text('All'), findsNothing, reason: '"All" is scrolled out of view to the left');
    final chip = tester.getRect(find.widgetWithText(CategoryCircleItem, 'Sub 7'));
    expect(chip.left, greaterThanOrEqualTo(0));
    expect(chip.right, lessThanOrEqualTo(375));
    expect(isSelected('Sub 7'), isTrue);

    // Tapping another chip selects it and scrolls it into view.
    await tester.tap(find.text('Sub 8'));
    await tester.pumpAndSettle();
    expect(taps, ['s8']);
    expect(isSelected('Sub 8'), isTrue);
    expect(isSelected('Sub 7'), isFalse);

    // Back to the start: "All" is the first chip and selecting it reports null.
    selected.value = 's0';
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(2000, 0));
    await tester.pumpAndSettle();
    expect(find.text('All'), findsOneWidget);
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(taps.last, isNull);
    expect(isSelected('All'), isTrue);

    // Wide screen: no sideways scrolling — every chip wraps onto the screen.
    tester.view.physicalSize = const Size(1000, 900);
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsNothing);
    for (final label in ['All', for (var i = 0; i < 9; i++) 'Sub $i']) {
      final rect = tester.getRect(find.widgetWithText(CategoryCircleItem, label));
      expect(rect.right, lessThanOrEqualTo(1000), reason: '$label fits on screen');
    }
    expect(tester.takeException(), isNull);
  });
}

/// A sideways row always ends mid-item at the screen edge — the cut-off item
/// is what tells people it scrolls.
void _pitchTests() {
  test('category circle row always shows a whole number of items plus half of the next', () {
    for (var width = 320.0; width <= 599; width += 1) {
      final pitch = categoryCirclePitch(width, 20);
      final visible = (width - 16) / pitch;
      expect(visible - visible.floorToDouble(), closeTo(0.5, 0.001), reason: 'at $width px');
      expect(pitch, inInclusiveRange(72, 100), reason: 'items stay a sensible size at $width px');
    }
  });

  test('a row that fits keeps full-width items, so names are not squeezed', () {
    for (var width = 320.0; width <= 599; width += 1) {
      expect(categoryCirclePitch(width, 3), 84, reason: 'at $width px');
    }
  });
}
