import 'package:everyday_wholesale/shared/widgets/inputs/app_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // No `EasyLocalization` ancestor: none of these cases hit this widget's one
  // `.tr()` call (the empty-results message), so there's nothing for it to
  // resolve — keeping the harness free of EasyLocalization's own async asset
  // load avoids that load racing (and sometimes losing) between the
  // sequential `testWidgets` blocks below.
  // A one-element box, not a returned value: the field's `onChanged` only
  // fires later, in response to a tap the test makes *after* pumping, so the
  // test needs a reference it can keep reading rather than a value snapshot
  // taken at pump time (always null then).
  Future<List<String?>> pumpSearchableField(WidgetTester tester) async {
    final selected = <String?>[null];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDropdownField<String>(
            hintText: 'Pick one',
            searchable: true,
            searchHintText: 'Search',
            items: const [
              AppDropdownItem(value: 'AL', label: 'Albania'),
              AppDropdownItem(value: 'BD', label: 'Bangladesh'),
              AppDropdownItem(value: 'LB', label: 'Lebanon'),
              AppDropdownItem(value: 'JP', label: 'Japan'),
            ],
            onChanged: (value) => selected[0] = value,
          ),
        ),
      ),
    );
    return selected;
  }

  testWidgets('opens as a bottom sheet and matches only the start of each label', (tester) async {
    await pumpSearchableField(tester);

    await tester.tap(find.text('Pick one'));
    await tester.pumpAndSettle();

    // All four present before any filtering.
    expect(find.text('Albania'), findsOneWidget);
    expect(find.text('Bangladesh'), findsOneWidget);
    expect(find.text('Lebanon'), findsOneWidget);
    expect(find.text('Japan'), findsOneWidget);

    // "ban" is a substring of Albania and Lebanon too, but should only
    // match Bangladesh, which *starts* with it.
    await tester.enterText(find.byType(TextField), 'ban');
    await tester.pumpAndSettle();

    expect(find.text('Bangladesh'), findsOneWidget);
    expect(find.text('Albania'), findsNothing);
    expect(find.text('Lebanon'), findsNothing);
    expect(find.text('Japan'), findsNothing);
  });

  testWidgets('selecting a filtered result closes the sheet and reports the value', (tester) async {
    final selected = await pumpSearchableField(tester);
    expect(selected[0], isNull);

    await tester.tap(find.text('Pick one'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ban');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bangladesh'));
    await tester.pumpAndSettle();

    // The sheet is gone, the field now shows the picked label, and the
    // value reported back is the item's code, not its display label.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Bangladesh'), findsOneWidget);
    expect(selected[0], 'BD');
  });

  testWidgets('empty query shows every item again', (tester) async {
    await pumpSearchableField(tester);

    await tester.tap(find.text('Pick one'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ban');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    expect(find.text('Albania'), findsOneWidget);
    expect(find.text('Bangladesh'), findsOneWidget);
    expect(find.text('Lebanon'), findsOneWidget);
    expect(find.text('Japan'), findsOneWidget);
  });
}
