import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:everyday_wholesale/config/di/injection_container.dart';
import 'package:everyday_wholesale/core/errors/failures.dart';
import 'package:everyday_wholesale/core/localization/app_locales.dart';
import 'package:everyday_wholesale/core/localization/japanese_font.dart';
import 'package:everyday_wholesale/core/localization/localized_text.dart';
import 'package:everyday_wholesale/core/utils/cart_totals.dart';
import 'package:everyday_wholesale/features/auth/domain/entities/user_entity.dart';
import 'package:everyday_wholesale/features/auth/domain/repositories/auth_repository.dart';
import 'package:everyday_wholesale/features/cart/domain/entities/cart_item_entity.dart';
import 'package:everyday_wholesale/features/cart/domain/repositories/cart_repository.dart';
import 'package:everyday_wholesale/features/cart/domain/usecases/clear_cart_usecase.dart';
import 'package:everyday_wholesale/features/cart/domain/usecases/get_cart_usecase.dart';
import 'package:everyday_wholesale/features/cart/domain/usecases/increment_cart_item_usecase.dart';
import 'package:everyday_wholesale/features/cart/domain/usecases/set_cart_item_quantity_usecase.dart';
import 'package:everyday_wholesale/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:everyday_wholesale/features/cart/presentation/widgets/cart_free_shipping_bar.dart';
import 'package:everyday_wholesale/features/cart/presentation/widgets/cart_item_card.dart';
import 'package:everyday_wholesale/features/cart/presentation/widgets/cart_summary_card.dart';
import 'package:everyday_wholesale/features/cart/presentation/widgets/cart_voucher_card.dart';
import 'package:everyday_wholesale/features/checkout/presentation/widgets/order_summary_card.dart';
import 'package:everyday_wholesale/features/checkout/presentation/widgets/payment_method_card.dart';
import 'package:everyday_wholesale/features/checkout/presentation/widgets/payment_method_sheet.dart';
import 'package:everyday_wholesale/features/home/domain/entities/category_entity.dart';
import 'package:everyday_wholesale/features/home/presentation/widgets/category_grid.dart';
import 'package:everyday_wholesale/features/order/domain/entities/order_item_entity.dart';
import 'package:everyday_wholesale/features/order/domain/entities/order_status.dart';
import 'package:everyday_wholesale/features/order/domain/entities/payment_status.dart';
import 'package:everyday_wholesale/features/order/presentation/widgets/order_address_card.dart';
import 'package:everyday_wholesale/features/order/presentation/widgets/order_info_row.dart';
import 'package:everyday_wholesale/features/order/presentation/widgets/order_item_tile.dart';
import 'package:everyday_wholesale/features/order/presentation/widgets/order_status_pill.dart';
import 'package:everyday_wholesale/features/order/presentation/widgets/payment_status_pill.dart';
import 'package:everyday_wholesale/features/product/domain/entities/product_condition.dart';
import 'package:everyday_wholesale/features/product/domain/entities/product_entity.dart';
import 'package:everyday_wholesale/features/product/presentation/widgets/product_highlight_boxes.dart';
import 'package:everyday_wholesale/features/product/presentation/widgets/product_info_row.dart';
import 'package:everyday_wholesale/features/review/domain/entities/reviewable_item_entity.dart';
import 'package:everyday_wholesale/features/review/presentation/widgets/reviewable_item_card.dart';
import 'package:everyday_wholesale/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:everyday_wholesale/features/wishlist/domain/usecases/add_to_wishlist_usecase.dart';
import 'package:everyday_wholesale/features/wishlist/domain/usecases/remove_from_wishlist_usecase.dart';
import 'package:everyday_wholesale/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'package:everyday_wholesale/shared/theme/app_theme.dart';
import 'package:everyday_wholesale/shared/widgets/cart_totals_breakdown.dart';
import 'package:everyday_wholesale/shared/widgets/navigation/breadcrumb_bar.dart';
import 'package:everyday_wholesale/shared/widgets/product_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

const _longName = LocalizedText(
  en: 'Noodles, Biscuits, Chanachur and Spicy Snack Mix Family Pack Extra Large',
  ja: 'ヌードル・ビスケット・チャナチュール・スパイシースナックミックス ファミリーパック 特大',
);

ProductEntity _product(String id, {int price = 123456}) => ProductEntity(
  id: id,
  name: _longName,
  price: price,
  unit: '5 kg (family pack, imported)',
  categoryId: 'c',
  iconKey: 'c',
  description: LocalizedText.empty,
  condition: ProductCondition.dryPackaged,
  origin: 'LK',
);

/// The cards/rows that used to overflow (or could) at narrow widths, long
/// Japanese labels or large accessibility text — rendered with the real
/// Plus Jakarta Sans at phone and desktop widths. Any RenderFlex overflow
/// fails the test.
void main() {
  setUpAll(() async {
    final cartRepo = _EmptyCartRepository();
    getIt.registerSingleton<CartBloc>(
      CartBloc(
        _NoAuth(),
        GetCartUseCase(cartRepo),
        SetCartItemQuantityUseCase(cartRepo),
        IncrementCartItemUseCase(cartRepo),
        ClearCartUseCase(cartRepo),
      ),
    );
    final wishlistRepo = _NoWishlist();
    getIt.registerSingleton<WishlistBloc>(
      WishlistBloc(AddToWishlistUseCase(wishlistRepo), RemoveFromWishlistUseCase(wishlistRepo)),
    );

    final jakarta = FontLoader(AppLocales.latinFontFamily);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      jakarta.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-$weight.ttf'));
    }
    await jakarta.load();
    // Real Japanese metrics too (the test font draws every glyph as a
    // full-em square, which would overstate Japanese-mode widths).
    for (final weight in ['Regular', 'Bold']) {
      await (FontLoader(
        JapaneseFont.family,
      )..addFont(rootBundle.load('assets/fonts/jp/NotoSansJP-$weight.ttf'))).load();
    }
  });

  final screens = <String, Widget Function()>{
    'product grid': () => ProductGrid(
      products: [for (var i = 0; i < 4; i++) _product('p$i')],
      onTap: (_) {},
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
    ),
    'category grid': () => CategoryGrid(
      categories: [for (var i = 0; i < 4; i++) CategoryEntity(id: 'c$i', name: _longName, iconKey: 'c')],
      onCategoryTap: (_) {},
    ),
    'cart item + totals': () => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CartItemCard(
            item: CartItemEntity(product: _product('p'), quantity: 99),
            onQuantityChanged: (_) {},
            onRemove: () {},
          ),
          const SizedBox(height: 16),
          CartTotalsBreakdown(totals: CartTotals.compute(9876543)),
        ],
      ),
    ),
    'order rows': () => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const OrderInfoRow(label: 'Payment method', value: 'Credit / debit card (Visa ending 4242)'),
          OrderLabeledRow(
            label: 'Order status',
            trailing: OrderStatusPill(status: OrderStatus.processing, onChanged: (_) {}),
          ),
          OrderLabeledRow(
            label: 'Payment status',
            trailing: PaymentStatusPill(status: PaymentStatus.failed, createdAt: DateTime(2026)),
          ),
          const OrderLabeledRow(label: 'Payment status', trailing: CodPaymentPill()),
        ],
      ),
    ),
    'product info + highlights': () => const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          ProductInfoRow(weight: '5 kg (family pack)', condition: ProductCondition.dryPackaged, origin: 'LK'),
          SizedBox(height: 16),
          ProductHighlightBoxes(),
        ],
      ),
    ),
    'cart page cards': () => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const CartFreeShippingBar(itemTotal: 1234),
          const SizedBox(height: 16),
          const CartVoucherCard(),
          const SizedBox(height: 16),
          CartSummaryCard(itemTotal: 9876543, onCheckout: () {}, onReturnToShopping: () {}),
        ],
      ),
    ),
    'checkout + order detail': () => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          OrderSummaryCard(items: [CartItemEntity(product: _product('p'), quantity: 99)], itemTotal: 9876543),
          const SizedBox(height: 16),
          PaymentMethodCard(selected: PaymentMethodOption.card, onTap: () {}),
          const SizedBox(height: 16),
          OrderItemTile(
            item: OrderItemEntity(
              productId: 'p',
              name: _longName,
              price: 123456,
              unit: '5 kg (family pack)',
              quantity: 99,
            ),
          ),
          const OrderAddressCard(
            receiverName: 'Mohammad Abdullah Al Mamun Chowdhury',
            addressLine: '〒348-0052 Saitama-ken, Hanyu-shi, Higashi 3-19-12, Everyday Mansion 201',
            phone: '+81 90-1234-5678',
          ),
        ],
      ),
    ),
    'breadcrumb': () => BreadcrumbBar(
      items: [
        BreadcrumbItem(label: 'Noodles, Biscuits, Chanachur and Snacks', onTap: () {}),
        BreadcrumbItem(label: 'Instant Noodles and Cup Ramen', onTap: () {}),
        BreadcrumbItem(label: _longName.en, onTap: () {}, isCurrent: true),
      ],
    ),
    'review card': () => Padding(
      padding: const EdgeInsets.all(16),
      child: ReviewableItemCard(
        item: ReviewableItemEntity(
          orderId: 'o',
          productId: 'p',
          productName: _longName,
          orderDate: DateTime(2026, 10, 2),
        ),
        isSubmitting: false,
        onRate: (_) {},
      ),
    ),
  };

  const widths = [320.0, 375.0, 1280.0];
  const textScales = [1.0, 1.3];

  // A single test: easy_localization caches its translation load, and a later
  // test's fake-async zone never sees that cached load finish — so the app is
  // mounted once and every combination is rendered inside it.
  testWidgets('no overflow: every screen × language × width × text size', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 2400);
    addTearDown(tester.view.reset);
    final current = ValueNotifier<(String, double)>((screens.keys.first, 1.0));
    late BuildContext appContext;

    // Translations load from the asset bundle (real async I/O).
    Future<void> settle() async {
      for (var i = 0; i < 100 && find.byType(Scaffold).evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: AppLocales.supported,
        path: 'assets/translations',
        fallbackLocale: AppLocales.fallback,
        startLocale: AppLocales.en,
        useOnlyLangCode: true,
        saveLocale: false,
        child: Builder(
          builder: (context) {
            appContext = context;
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              theme: AppTheme.light(bodyFont: AppLocales.bodyFontFor(context.locale)),
              home: ValueListenableBuilder(
                valueListenable: current,
                builder: (context, value, _) => MediaQuery.withClampedTextScaling(
                  minScaleFactor: value.$2,
                  maxScaleFactor: value.$2,
                  child: Scaffold(
                    key: ValueKey(value),
                    body: SingleChildScrollView(child: screens[value.$1]!()),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await settle();

    final failures = <String>[];
    var rendered = 0;
    for (final locale in AppLocales.supported) {
      if (appContext.locale != locale) {
        await tester.runAsync(() => appContext.setLocale(locale));
        await settle();
      }
      for (final name in screens.keys) {
        for (final width in widths) {
          for (final scale in textScales) {
            tester.view.physicalSize = Size(width, 2400);
            current.value = (name, scale);
            await tester.pumpAndSettle();
            if (find.byType(Scaffold).evaluate().isNotEmpty) rendered++;
            final error = tester.takeException();
            if (error != null) failures.add('${locale.languageCode} · $name · ${width.toInt()} wide · ×$scale: $error');
          }
        }
      }
    }

    expect(rendered, AppLocales.supported.length * screens.length * widths.length * textScales.length);
    expect(failures, isEmpty);
  });
}
