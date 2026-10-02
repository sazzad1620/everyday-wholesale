import 'package:everyday_wholesale/core/utils/product_image_cleaner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

img.Image _canvas(int w, int h, img.Color color) => img.Image(width: w, height: h)..clear(color);

void _fillRect(img.Image image, int x0, int y0, int x1, int y1, img.Color color) {
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      image.setPixel(x, y, color);
    }
  }
}

void main() {
  final offWhite = img.ColorRgb8(240, 236, 226);
  final red = img.ColorRgb8(200, 30, 30);

  test('turns an off-white background pure white and trims the margin', () {
    final image = _canvas(400, 400, offWhite);
    _fillRect(image, 150, 100, 250, 300, red); // 100x200 product, big margins

    final cleaned = ProductImageCleaner.cleanImage(image)!;

    // Cropped to the product plus a thin margin, not the original 400x400.
    expect(cleaned.width, lessThan(140));
    expect(cleaned.height, lessThan(240));
    expect(cleaned.width, greaterThanOrEqualTo(100));
    expect(cleaned.height, greaterThanOrEqualTo(200));

    // The corner (former off-white background) is now pure white.
    final corner = cleaned.getPixel(0, 0);
    expect([corner.r, corner.g, corner.b], [255, 255, 255]);
    // The product is untouched.
    final centre = cleaned.getPixel(cleaned.width ~/ 2, cleaned.height ~/ 2);
    expect([centre.r, centre.g, centre.b], [200, 30, 30]);
  });

  test('leaves plain-white areas inside the product alone', () {
    final image = _canvas(300, 300, offWhite);
    _fillRect(image, 80, 80, 220, 220, red);
    _fillRect(image, 130, 130, 170, 170, offWhite); // enclosed hole, e.g. a label

    final cleaned = ProductImageCleaner.cleanImage(image)!;
    final hole = cleaned.getPixel(cleaned.width ~/ 2, cleaned.height ~/ 2);

    // Not connected to the border, so it is NOT flood-filled to pure white.
    expect([hole.r, hole.g, hole.b], [240, 236, 226]);
  });

  test('leaves a full-bleed photo untouched', () {
    final image = _canvas(300, 300, red);
    _fillRect(image, 100, 100, 200, 200, offWhite);

    expect(ProductImageCleaner.cleanImage(image), isNull);
  });

  test('leaves a dark plain background untouched', () {
    final image = _canvas(300, 300, img.ColorRgb8(20, 20, 20));
    _fillRect(image, 100, 100, 200, 200, red);

    expect(ProductImageCleaner.cleanImage(image), isNull);
  });

  test('a photo that is already pure white and tight is left alone', () {
    final image = _canvas(100, 100, red);
    // No plain light border at all.
    expect(ProductImageCleaner.cleanImage(image), isNull);
  });

  test('a blank white image is left alone', () {
    expect(ProductImageCleaner.cleanImage(_canvas(200, 200, img.ColorRgb8(255, 255, 255))), isNull);
  });
}
