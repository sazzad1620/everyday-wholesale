import 'package:easy_localization/easy_localization.dart';
import 'package:everyday_wholesale/config/di/injection_container.dart';
import 'package:everyday_wholesale/core/errors/failures.dart';
import 'package:everyday_wholesale/core/localization/app_locales.dart';
import 'package:everyday_wholesale/core/localization/localized_text.dart';
import 'package:everyday_wholesale/features/auth/domain/entities/user_entity.dart';
import 'package:everyday_wholesale/features/auth/domain/repositories/auth_repository.dart';
import 'package:everyday_wholesale/features/cart/domain/entities/cart_item_entity.dart';
import 'package:everyday_wholesale/features/cart/domain/repositories/cart_repository.dart';
import 'package:everyday_wholesale/features/cart/domain/usecases/clear_cart_usecase.dart';
import 'package:everyday_wholesale/features/cart/domain/usecases/get_cart_usecase.dart';
import 'package:everyday_wholesale/features/cart/domain/usecases/increment_cart_item_usecase.dart';
import 'package:everyday_wholesale/features/cart/domain/usecases/set_cart_item_quantity_usecase.dart';
import 'package:everyday_wholesale/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:everyday_wholesale/features/home/presentation/widgets/home_product_row.dart';
import 'package:everyday_wholesale/features/product/domain/entities/product_condition.dart';
import 'package:everyday_wholesale/features/product/domain/entities/product_entity.dart';
import 'package:everyday_wholesale/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:everyday_wholesale/features/wishlist/domain/usecases/add_to_wishlist_usecase.dart';
import 'package:everyday_wholesale/features/wishlist/domain/usecases/remove_from_wishlist_usecase.dart';
import 'package:everyday_wholesale/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'package:everyday_wholesale/shared/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _EmptyCartRepository implements CartRepository {
  @override
  Future<Either<Failure, List<CartItemEntity>>> getCart() async => const Right([]);
  @override
  Future<Either<Failure, void>> setQuantity(String productId, int quantity) async => const Right(null);
  @override
  Future<Either<Failure, void>> incrementQuantity(String productId, int by) async => const Right(null);
  @override
  Future<Either<Failure, void>> clear() async => const Right(null);
}

class _NoAuth implements AuthRepository {
  @override
  Stream<UserEntity?> get authStateChanges => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoWishlist implements WishlistRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProductEntity _product(int i) => ProductEntity(
  id: 'p$i',
  name: LocalizedText(en: 'Product $i'),
  price: 100 + i,
  unit: '1 kg',
  categoryId: 'c',
  iconKey: 'c',
  description: LocalizedText.empty,
  condition: ProductCondition.dryPackaged,
  origin: 'JP',
);

/// A phone shows 2½ cards (the cut-off one says "swipe"); a wide screen gets
/// ◀ ▶ buttons that appear only while there is more in that direction.
void main() {
  setUpAll(() {
    final repo = _EmptyCartRepository();
    getIt.registerSingleton<CartBloc>(
      CartBloc(
        _NoAuth(),
        GetCartUseCase(repo),
        SetCartItemQuantityUseCase(repo),
        IncrementCartItemUseCase(repo),
        ClearCartUseCase(repo),
      ),
    );
    final wishlist = _NoWishlist();
    getIt.registerSingleton<WishlistBloc>(
      WishlistBloc(AddToWishlistUseCase(wishlist), RemoveFromWishlistUseCase(wishlist)),
    );
  });

  // One test with one mounted app: easy_localization caches its translation
  // load, and a second test's fake-async zone never sees that load finish.
  testWidgets('phone peeks the next card; wide screens get arrows only where there is more', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final shown = ValueNotifier<(int count, bool viewAllCard)>((8, true));

    tester.view.physicalSize = const Size(375, 900);
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
              body: SingleChildScrollView(
                child: ValueListenableBuilder(
                  valueListenable: shown,
                  builder: (context, value, _) => HomeProductRow(
                    key: ValueKey(value),
                    title: 'Rice',
                    products: [for (var i = 0; i < value.$1; i++) _product(i)],
                    endWithViewAllCard: value.$2,
                    onProductTap: (_) {},
                    onViewAll: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Translations load from the asset bundle (real async I/O).
    for (var i = 0; i < 100 && find.byType(ProductCard).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    double opacityOf(IconData icon) {
      final iconFinder = find.byIcon(icon, skipOffstage: false);
      for (final element in find.byType(AnimatedOpacity, skipOffstage: false).evaluate()) {
        if (find.descendant(of: find.byWidget(element.widget), matching: iconFinder).evaluate().isNotEmpty) {
          return (element.widget as AnimatedOpacity).opacity;
        }
      }
      throw StateError('no arrow button for $icon');
    }

    // Phone: the third card is cut off by the screen edge; no arrow buttons.
    final card = tester.getRect(find.byType(ProductCard).first);
    expect(card.width, inInclusiveRange(124, 160));
    expect((375 - 16) / (card.width + 8), inInclusiveRange(2.2, 2.7), reason: 'about 2½ cards across');
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(find.text('View All'), findsOneWidget, reason: 'header link only (the last card is off-screen)');

    // Desktop: ◀ hidden at the start, ▶ shown; scrolling flips them.
    tester.view.physicalSize = const Size(1000, 900);
    await tester.pumpAndSettle();
    expect(opacityOf(Icons.chevron_left_rounded), 0, reason: 'nothing to the left yet');
    expect(opacityOf(Icons.chevron_right_rounded), 1);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(opacityOf(Icons.chevron_left_rounded), 1);

    for (var i = 0; i < 6 && opacityOf(Icons.chevron_right_rounded) != 0; i++) {
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
    }
    expect(opacityOf(Icons.chevron_right_rounded), 0, reason: 'reached the end');
    expect(find.text('View All'), findsNWidgets(2), reason: 'header link + the last card');

    // A row that fits on screen shows no arrows at all.
    shown.value = (2, false);
    await tester.pumpAndSettle();
    expect(opacityOf(Icons.chevron_left_rounded), 0);
    expect(opacityOf(Icons.chevron_right_rounded), 0);
    expect(tester.takeException(), isNull);
  });
}
