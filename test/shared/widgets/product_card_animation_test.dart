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
import 'package:everyday_wholesale/features/cart/presentation/bloc/cart_state.dart';
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

/// Lets the test put the cart into a given state without a signed-in user.
class _SeedableCartBloc extends CartBloc {
  _SeedableCartBloc(CartRepository repo)
    : super(
        _NoAuth(),
        GetCartUseCase(repo),
        SetCartItemQuantityUseCase(repo),
        IncrementCartItemUseCase(repo),
        ClearCartUseCase(repo),
      );

  void seed(CartState state) => emit(state);
}

const _product = ProductEntity(
  id: 'rice',
  name: LocalizedText(en: 'Keri Samba Rice'),
  price: 3550,
  unit: '5 kg',
  categoryId: 'c',
  iconKey: 'c',
  description: LocalizedText.empty,
  condition: ProductCondition.dryPackaged,
  origin: 'LK',
);

/// Adding to the cart grows the quantity pill out of the cart button instead
/// of swapping instantly, and removing the last one shrinks it back.
void main() {
  late _SeedableCartBloc cart;

  setUpAll(() {
    cart = _SeedableCartBloc(_EmptyCartRepository());
    getIt.registerSingleton<CartBloc>(cart);
    final wishlistRepo = _NoWishlist();
    getIt.registerSingleton<WishlistBloc>(
      WishlistBloc(AddToWishlistUseCase(wishlistRepo), RemoveFromWishlistUseCase(wishlistRepo)),
    );
  });

  testWidgets('cart button ↔ quantity pill animates', (tester) async {
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
              body: Center(
                child: SizedBox(
                  width: 180,
                  height: 180 + ProductCard.contentHeight(TextScaler.noScaling),
                  child: ProductCard(product: _product, onTap: () {}),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 100 && find.byType(ProductCard).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final addButton = find.byIcon(Icons.add_shopping_cart_rounded);
    final pillPlus = find.byIcon(Icons.add_rounded);
    expect(addButton, findsOneWidget);
    expect(pillPlus, findsNothing);

    // Added: mid-animation both are on screen, the pill still growing.
    cart.seed(const CartState(items: [CartItemEntity(product: _product, quantity: 1)]));
    await tester.pump(); // bloc delivers the new state
    await tester.pump(); // card rebuilds; the switch starts
    await tester.pump(const Duration(milliseconds: 80));
    expect(addButton, findsOneWidget);
    expect(pillPlus, findsOneWidget);
    final growing = tester.widget<ScaleTransition>(
      find.ancestor(
        of: pillPlus,
        matching: find.byWidgetPredicate((w) => w is ScaleTransition && w.alignment == Alignment.centerRight),
      ),
    );
    expect(growing.scale.value, inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(addButton, findsNothing);
    expect(pillPlus, findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // Quantity changes roll the number.
    cart.seed(const CartState(items: [CartItemEntity(product: _product, quantity: 2)]));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Back to zero: the pill shrinks back into the button.
    cart.seed(const CartState());
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(pillPlus, findsOneWidget);
    await tester.pumpAndSettle();
    expect(pillPlus, findsNothing);
    expect(addButton, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
