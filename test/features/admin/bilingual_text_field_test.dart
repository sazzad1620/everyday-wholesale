import 'package:everyday_wholesale/core/localization/localized_text.dart';
import 'package:everyday_wholesale/features/admin/presentation/widgets/bilingual_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child, {double width = 400}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `.tr()` on an uninitialised easy_localization returns the key itself,
  // which is enough here — these tests are about validation and layout.

  testWidgets('EN is required, JA is optional', (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = BilingualController();
    await _pump(
      tester,
      Form(
        key: formKey,
        child: BilingualTextField(controller: controller, hintText: 'Name', requiredError: 'EN required'),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('EN required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Rice');
    expect(formKey.currentState!.validate(), isTrue);
    expect(controller.value, const LocalizedText(en: 'Rice'));
  });

  testWidgets('composes both languages and pre-fills from an initial value', (tester) async {
    final controller = BilingualController(const LocalizedText(en: 'Rice', ja: '米'));
    await _pump(tester, BilingualTextField(controller: controller, hintText: 'Name'));

    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('米'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).last, ' 白米 ');
    expect(controller.value, const LocalizedText(en: 'Rice', ja: '白米'));
  });

  testWidgets('no requiredError means a blank field validates', (tester) async {
    final formKey = GlobalKey<FormState>();
    await _pump(
      tester,
      Form(key: formKey, child: BilingualTextField(controller: BilingualController(), hintText: 'Sub')),
    );
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('stacks on phone width, side by side on wide', (tester) async {
    await _pump(tester, BilingualTextField(controller: BilingualController(), hintText: 'Name'), width: 400);
    final narrow = tester.getTopLeft(find.byType(TextFormField).first).dy != tester.getTopLeft(find.byType(TextFormField).last).dy;
    expect(narrow, isTrue, reason: 'phone: JA box should be below EN box');

    await _pump(tester, BilingualTextField(controller: BilingualController(), hintText: 'Name'), width: 700);
    final wide = tester.getTopLeft(find.byType(TextFormField).first).dy == tester.getTopLeft(find.byType(TextFormField).last).dy;
    expect(wide, isTrue, reason: 'wide: boxes should share a row');
  });

  testWidgets('MissingJaBadge shows only when JA is blank', (tester) async {
    await _pump(tester, const MissingJaBadge(text: LocalizedText(en: 'Rice')));
    expect(find.byType(Container), findsOneWidget);

    await _pump(tester, const MissingJaBadge(text: LocalizedText(en: 'Rice', ja: '米')));
    expect(find.byType(Container), findsNothing);
  });
}
