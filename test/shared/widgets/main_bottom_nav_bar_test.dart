import 'dart:async';

import 'package:everyday_wholesale/config/di/injection_container.dart';
import 'package:everyday_wholesale/core/errors/failures.dart';
import 'package:everyday_wholesale/features/auth/domain/entities/user_entity.dart';
import 'package:everyday_wholesale/features/auth/domain/repositories/auth_repository.dart';
import 'package:everyday_wholesale/features/cart/domain/entities/cart_item_entity.dart';
import 'package:everyday_wholesale/features/cart/domain/repositories/cart_repository.dart';
import 'package:everyday_wholesale/features/cart/domain/usecases/clear_cart_usecase.dart';
import 'package:everyday_wholesale/features/cart/domain/usecases/get_cart_usecase.dart';
import 'package:everyday_wholesale/features/cart/domain/usecases/increment_cart_item_usecase.dart';
import 'package:everyday_wholesale/features/cart/domain/usecases/set_cart_item_quantity_usecase.dart';
import 'package:everyday_wholesale/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:everyday_wholesale/shared/widgets/navigation/main_bottom_nav_bar.dart';
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

/// The floating bar must sit fully above whatever the system reserves at
/// the bottom — nothing (phone browsers), Android's gesture bar, Android's
/// 2/3-button bar, or the iPhone home indicator — and never overflow, down
/// to small 320pt phones and short landscape screens. Nothing may be painted
/// above the pill (the page shows around its corners), and the page gets the
/// bar's full height as bottom padding so its last item can scroll clear.
void main() {
  setUpAll(() {
    final repo = _EmptyCartRepository();
    getIt.registerSingleton<CartBloc>(
      CartBloc(_NoAuth(), GetCartUseCase(repo), SetCartItemQuantityUseCase(repo), IncrementCartItemUseCase(repo), ClearCartUseCase(repo)),
    );
  });

  const insets = {'no system bar': 0.0, 'Android gesture bar': 24.0, 'Android 3-button bar': 48.0, 'iPhone home indicator': 34.0};
  // Portrait phones, plus phone browsers in landscape (still < 600 wide, so
  // the bottom bar shows).
  const sizes = [Size(320, 700), Size(375, 812), Size(412, 915), Size(568, 320), Size(590, 360)];

  for (final size in sizes) {
    for (final entry in insets.entries) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}, ${entry.key}: pill clears the system area, no overflow', (tester) async {
        final height = size.height;
        final short = height < 480;
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        tester.view.padding = FakeViewPadding(bottom: entry.value * 3);
        tester.view.viewPadding = FakeViewPadding(bottom: entry.value * 3);
        addTearDown(tester.view.reset);

        late double bodyBottomPadding;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              extendBody: true,
              body: Builder(builder: (context) {
                bodyBottomPadding = MediaQuery.paddingOf(context).bottom;
                return const SizedBox.expand();
              }),
              bottomNavigationBar: MainBottomNavBar(navigationShell: null, onCategoryTap: () {}),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        // The pill is the rounded DecoratedBox (radius 28) inside the bar.
        final pill = find.byWidgetPredicate(
          (w) => w is DecoratedBox && w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).borderRadius == BorderRadius.circular(28),
        );
        expect(pill, findsOneWidget);
        final rect = tester.getRect(pill);
        expect(rect.bottom, lessThanOrEqualTo(height - entry.value), reason: 'pill must end above the system area');
        expect(rect.bottom, lessThanOrEqualTo(height - (short ? 6 : 10)), reason: 'always a visible gap below the pill');
        expect(rect.left, greaterThanOrEqualTo(8), reason: 'floats off the side edges');
        expect(rect.width, lessThanOrEqualTo(480), reason: 'stays a compact pill in landscape');
        expect(rect.center.dx, closeTo(size.width / 2, 0.01));
        final bar = tester.getRect(find.byType(MainBottomNavBar));
        expect(bar.top, rect.top, reason: 'nothing above the pill — content shows around its corners');
        expect(bodyBottomPadding, closeTo(bar.height, 0.01), reason: 'pages pad their scroll views by the bar height');
        expect(rect.height, short ? inInclusiveRange(44, 64) : inInclusiveRange(56, 76));
        for (final label in ['nav.home', 'nav.category', 'nav.wishlist', 'nav.cart']) {
          expect(find.text(label), findsOneWidget);
        }
      });
    }
  }
}
