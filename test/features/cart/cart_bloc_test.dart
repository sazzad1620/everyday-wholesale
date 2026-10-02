import 'dart:async';

import 'package:everyday_wholesale/core/errors/failures.dart';
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
import 'package:everyday_wholesale/features/cart/presentation/bloc/cart_event.dart';
import 'package:everyday_wholesale/features/product/domain/entities/product_condition.dart';
import 'package:everyday_wholesale/features/product/domain/entities/product_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

ProductEntity product(String id, {int price = 100}) => ProductEntity(
  id: id,
  name: LocalizedText(en: id),
  price: price,
  unit: '1',
  categoryId: 'c',
  iconKey: 'c',
  description: LocalizedText.empty,
  condition: ProductCondition.dryPackaged,
  origin: 'JP',
);

/// In-memory "Firestore" cart whose writes can be slowed down or failed.
class FakeCartRepository implements CartRepository {
  final Map<String, int> saved = {};
  final Map<String, ProductEntity> products = {};
  final List<String> writes = [];
  Duration writeDelay = Duration.zero;
  bool failNextWrite = false;

  Future<Either<Failure, void>> _write(String log, void Function() apply) async {
    await Future<void>.delayed(writeDelay);
    writes.add(log);
    if (failNextWrite) {
      failNextWrite = false;
      return const Left(UnexpectedFailure());
    }
    apply();
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<CartItemEntity>>> getCart() async => Right([
    for (final e in saved.entries) CartItemEntity(product: products[e.key] ?? product(e.key), quantity: e.value),
  ]);

  @override
  Future<Either<Failure, void>> setQuantity(String productId, int quantity) => _write('set $productId=$quantity', () {
    if (quantity <= 0) {
      saved.remove(productId);
    } else {
      saved[productId] = quantity;
    }
  });

  @override
  Future<Either<Failure, void>> incrementQuantity(String productId, int by) =>
      _write('inc $productId+$by', () => saved[productId] = (saved[productId] ?? 0) + by);

  @override
  Future<Either<Failure, void>> clear() => _write('clear', saved.clear);
}

class FakeAuthRepository implements AuthRepository {
  final controller = StreamController<UserEntity?>.broadcast();

  @override
  Stream<UserEntity?> get authStateChanges => controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeCartRepository repo;
  late FakeAuthRepository auth;
  late CartBloc bloc;

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

  setUp(() async {
    repo = FakeCartRepository();
    auth = FakeAuthRepository();
    bloc = CartBloc(
      auth,
      GetCartUseCase(repo),
      SetCartItemQuantityUseCase(repo),
      IncrementCartItemUseCase(repo),
      ClearCartUseCase(repo),
    );
    auth.controller.add(const UserEntity(uid: 'u', email: 'e', name: 'n'));
    await settle();
  });

  tearDown(() => bloc.close());

  int quantityOf(String id) =>
      bloc.state.items.where((i) => i.product.id == id).fold(0, (_, i) => i.quantity);

  test('adding shows in the cart before the save has finished', () async {
    repo.writeDelay = const Duration(milliseconds: 300);
    bloc.add(CartItemAdded(product('a'), 1));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(quantityOf('a'), 1, reason: 'screen updated immediately');
    expect(repo.saved, isEmpty, reason: 'save still in flight');

    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(repo.saved, {'a': 1});
    expect(repo.writes, ['inc a+1'], reason: 'new item is added atomically, not overwritten');
  });

  test('rapid +/- taps update instantly and coalesce into few writes with the right final value', () async {
    repo.writeDelay = const Duration(milliseconds: 100);
    bloc.add(CartItemAdded(product('a'), 1));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    for (var q = 2; q <= 6; q++) {
      bloc.add(CartQuantityChanged('a', q));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(quantityOf('a'), q);
    }
    bloc.add(const CartQuantityChanged('a', 5)); // one "−"
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(quantityOf('a'), 5);

    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(repo.saved, {'a': 5}, reason: 'Firestore ends at the last tapped value');
    expect(repo.writes.length, lessThan(7), reason: '7 taps must not mean 7 writes');
    expect(repo.writes.last, 'set a=5');
  });

  test('a failed save restores the real cart and reports an error', () async {
    repo.saved['a'] = 2;
    bloc.add(const CartReloadRequested());
    await settle();
    expect(quantityOf('a'), 2);

    repo.failNextWrite = true;
    repo.writeDelay = const Duration(milliseconds: 100);
    bloc.add(const CartQuantityChanged('a', 3));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(quantityOf('a'), 3, reason: 'optimistic');

    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(quantityOf('a'), 2, reason: 'rolled back to what Firestore really has');
    expect(bloc.state.syncErrorCount, 1);
    expect(bloc.state.syncErrorKey, isNotNull);
  });

  test('removing and clearing update instantly and persist', () async {
    bloc.add(CartItemAdded(product('a'), 2));
    bloc.add(CartItemAdded(product('b'), 1));
    await settle();
    bloc.add(const CartItemRemoved('a'));
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(quantityOf('a'), 0);
    await settle();
    expect(repo.saved, {'b': 1});

    bloc.add(const CartCleared());
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(bloc.state.items, isEmpty);
    await settle();
    expect(repo.saved, isEmpty);
  });

  test('adding while the cart is still loading merges with the saved cart', () async {
    // Fresh sign-in with an existing saved cart that loads slowly.
    await bloc.close();
    repo = FakeCartRepository()..saved['a'] = 2;
    final slowRepo = _SlowLoadRepository(repo);
    bloc = CartBloc(
      auth,
      GetCartUseCase(slowRepo),
      SetCartItemQuantityUseCase(slowRepo),
      IncrementCartItemUseCase(slowRepo),
      ClearCartUseCase(slowRepo),
    );
    auth.controller.add(const UserEntity(uid: 'u', email: 'e', name: 'n'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    bloc.add(CartItemAdded(product('a'), 1)); // tapped before the load finished

    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(repo.saved['a'], 3, reason: 'incremented, not overwritten to 1');
    expect(quantityOf('a'), 3, reason: 'screen shows the merged result');
  });
}

/// Delays only `getCart`, to simulate a cart still loading after sign-in.
class _SlowLoadRepository implements CartRepository {
  _SlowLoadRepository(this.inner);
  final FakeCartRepository inner;

  @override
  Future<Either<Failure, List<CartItemEntity>>> getCart() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return inner.getCart();
  }

  @override
  Future<Either<Failure, void>> setQuantity(String productId, int quantity) => inner.setQuantity(productId, quantity);

  @override
  Future<Either<Failure, void>> incrementQuantity(String productId, int by) => inner.incrementQuantity(productId, by);

  @override
  Future<Either<Failure, void>> clear() => inner.clear();
}
