import 'package:everyday_wholesale/shared/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('photos are decoded at the size they are shown, in steps of 64 px, never beyond 1920', (tester) async {

    late BuildContext context;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 2),
        child: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(decodeWidthFor(context, 150), 320); // 300 px -> next multiple of 64
    expect(decodeWidthFor(context, 64), 128);
    expect(decodeWidthFor(context, 10), 64, reason: 'never below 64');
    expect(decodeWidthFor(context, 5000), 1920, reason: 'capped');
    expect(decodeWidthFor(context, double.infinity), isNull);
    expect(decodeWidthFor(context, 0), isNull);
  });
}
