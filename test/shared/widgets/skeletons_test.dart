import 'package:everyday_wholesale/shared/widgets/loaders/skeletons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The page skeletons are dropped into pages in place of a spinner: they must
/// lay out without overflow on a phone, a tablet and a desktop, and at large
/// accessibility text sizes.
void main() {
  const sizes = [Size(360, 640), Size(820, 1100), Size(1400, 900)];
  final skeletons = <String, Widget>{
    'home': const HomeSkeleton(),
    'categories': const CategoriesSkeleton(),
    'detail': const ProductDetailSkeleton(),
    'grid': const ProductGridSkeleton(padding: EdgeInsets.symmetric(horizontal: 16)),
    'offers': const CardListSkeleton(count: 3, header: 150, lines: 2, maxWidth: 720),
    'orders': const CardListSkeleton(count: 4, lines: 3),
  };

  for (final size in sizes) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('skeletons fit at ${size.width.toInt()} px, text x$scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        for (final entry in skeletons.entries) {
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: MediaQuery(
                data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
                child: Material(child: Column(children: [Expanded(child: entry.value)])),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: '${entry.key} threw');
        }
      });
    }
  }
}
