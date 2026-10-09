import 'package:everyday_wholesale/shared/widgets/image_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// While a photo has no frame yet, its whole tile must show the shimmer.
/// (It once painted nothing: inside the AnimatedSwitcher it got loose
/// constraints and shrank to 0 × 0.)
void main() {
  testWidgets('the shimmer fills the tile until the first frame, then the photo replaces it', (tester) async {
    Widget tile(int? frame) => Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 300,
          height: 120,
          child: Builder(
            builder: (context) => imageFadeIn(context, const SizedBox.expand(), frame, false),
          ),
        ),
      ),
    );

    await tester.pumpWidget(tile(null));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getSize(find.byType(ImageShimmer)), const Size(300, 120));

    await tester.pumpWidget(tile(0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ImageShimmer), findsNothing);
  });

  testWidgets('the sweep (no fill) leaves the tile white and moves left to right', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: const ColoredBox(
              color: Colors.white,
              child: SizedBox(width: 300, height: 100, child: ImageShimmer(fill: false)),
            ),
          ),
        ),
      ),
    );

    Future<List<int>> row() async {
      final pixels = await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final data = (await (await boundary.toImage()).toByteData())!;
        return [for (var x = 0; x < 300; x++) data.getUint8((50 * 300 + x) * 4)];
      });
      return pixels!;
    }

    int darkestX(List<int> p) => p.indexOf(p.reduce((a, b) => a < b ? a : b));

    await tester.pump(const Duration(milliseconds: 800)); // ~36% through the 2.2 s cycle
    final early = await row();
    await tester.pump(const Duration(milliseconds: 500)); // ~59%
    final later = await row();

    expect(early.reduce((a, b) => a > b ? a : b), greaterThanOrEqualTo(253), reason: "no grey fill: the tile stays (nearly) white away from the glow");
    expect(later.reduce((a, b) => a < b ? a : b), lessThan(250), reason: 'the band itself is visible');
    expect(darkestX(later), greaterThan(darkestX(early)), reason: 'the band travels from left to right');
  });
}
