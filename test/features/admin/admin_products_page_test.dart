import 'package:easy_localization/easy_localization.dart';
import 'package:everyday_wholesale/config/di/injection_container.dart';
import 'package:everyday_wholesale/core/errors/failures.dart';
import 'package:everyday_wholesale/core/localization/app_locales.dart';
import 'package:everyday_wholesale/core/localization/localized_text.dart';
import 'package:everyday_wholesale/features/admin/presentation/bloc/products/admin_product_list_bloc.dart';
import 'package:everyday_wholesale/features/admin/presentation/pages/products/admin_products_page.dart';
import 'package:everyday_wholesale/features/product/domain/entities/product_condition.dart';
import 'package:everyday_wholesale/features/product/domain/entities/product_entity.dart';
import 'package:everyday_wholesale/features/product/domain/repositories/admin_product_repository.dart';
import 'package:everyday_wholesale/features/product/domain/usecases/delete_product_usecase.dart';
import 'package:everyday_wholesale/features/product/domain/usecases/get_all_products_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

ProductEntity _product(String id, String en, {String ja = '', bool popular = false, bool inStock = true}) => ProductEntity(
  id: id,
  name: LocalizedText(en: en, ja: ja),
  price: 1200,
  unit: '1 kg',
  categoryId: 'c',
  iconKey: 'c',
  description: LocalizedText.empty,
  condition: ProductCondition.dryPackaged,
  origin: 'JP',
  isMostPopular: popular,
  inStock: inStock,
);

class _FakeRepository implements AdminProductRepository {
  _FakeRepository(this.products);

  final List<ProductEntity> products;

  @override
  Future<Either<Failure, List<ProductEntity>>> getAllProducts() async => Right(products);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app() => EasyLocalization(
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
      home: const Scaffold(body: AdminProductsPage()),
    ),
  ),
);

/// Admin product list: the search box filters this same list word by word,
/// and the status tags sit under the name on a phone (where beside it they
/// used to squeeze the name down to a few letters) but beside it on a wide
/// screen.
///
/// One test with one mounted app: easy_localization caches its translation
/// load, and a second test's fake-async zone never sees that load finish.
void main() {
  setUpAll(() {
    final repo = _FakeRepository([
      _product('1', 'Indian Basmati Rice Extra Long Grain Premium Quality 5kg', popular: true),
      _product('2', 'Wheat Flour', ja: '小麦粉'),
      _product('3', 'Keri Samba Rice', ja: 'ケリサンバ米', inStock: false),
      _product('4', 'Brown Rice', ja: 'ブラウンライス'),
    ]);
    getIt.registerFactory<AdminProductListBloc>(
      () => AdminProductListBloc(GetAllProductsUseCase(repo), DeleteProductUseCase(repo)),
    );
  });

  testWidgets('search is word-wise; tags sit under the name on a phone and beside it on a wide screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // ---- Phone ------------------------------------------------------------
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpWidget(_app());
    // Translations load from the asset bundle (real async I/O).
    for (var i = 0; i < 100 && find.text('Wheat Flour').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(find.text('Wheat Flour'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'no overflow on a 360pt phone');

    final longName = find.text('Indian Basmati Rice Extra Long Grain Premium Quality 5kg');
    final missingJa = find.text('JA missing');
    final everyday = find.text('Everyday');
    expect(longName, findsOneWidget);
    expect(missingJa, findsOneWidget, reason: 'only product 1 lacks Japanese');

    // Under the name, not beside it: the tags start below where the name ends,
    // and the name keeps the row's full width (it wraps to two lines).
    expect(tester.getTopLeft(missingJa).dy, greaterThan(tester.getBottomLeft(longName).dy - 1));
    expect(tester.getTopLeft(everyday).dy, greaterThan(tester.getBottomLeft(longName).dy - 1));
    expect(tester.getSize(longName).height, greaterThan(24), reason: 'long name shows on two lines instead of being cut');

    // ---- Search: word beginnings only --------------------------------------
    Future<void> search(String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
    }

    await search('ric');
    expect(find.text('Keri Samba Rice'), findsOneWidget);
    expect(find.text('Brown Rice'), findsOneWidget);
    expect(longName, findsOneWidget);
    expect(find.text('Wheat Flour'), findsNothing);
    expect(find.text('3 of 4 products'), findsOneWidget);

    await search('indi bas');
    expect(longName, findsOneWidget);
    expect(find.text('Brown Rice'), findsNothing);

    await search('ndi');
    expect(find.text('No matching product'), findsOneWidget, reason: 'middle of a word does not match');
    expect(longName, findsNothing);

    await search('ic');
    expect(find.text('No matching product'), findsOneWidget);

    // The Japanese name is searched too, in either kana script (no word
    // boundaries in Japanese, so it matches anywhere in the name).
    await search('らいす');
    expect(find.text('Brown Rice'), findsOneWidget);
    await search('ライス');
    expect(find.text('Brown Rice'), findsOneWidget);

    // Clearing the box restores the whole list.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(find.text('Wheat Flour'), findsOneWidget);
    expect(find.text('Brown Rice'), findsOneWidget);

    // ---- Wide screen: tags stay beside the name ----------------------------
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    final nameBox = tester.getRect(find.text('Indian Basmati Rice Extra Long Grain Premium Quality 5kg'));
    final tagBox = tester.getRect(find.text('JA missing'));
    expect(tagBox.left, greaterThan(nameBox.right - 1), reason: 'tag is to the right of the name');
    expect((tagBox.center.dy - nameBox.center.dy).abs(), lessThan(30), reason: 'same row as the name');
  });
}
