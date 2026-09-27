import 'dart:typed_data';

import 'package:everyday_wholesale/core/utils/image_optimizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('resizes to each max dimension, never upscales, and outputs JPEG', () async {
    // Noisy, photo-like content — a flat colour compresses to almost nothing
    // as PNG and wouldn't say anything about real-world savings.
    final source = img.noise(img.Image(width: 3000, height: 2000), 60);
    final png = Uint8List.fromList(img.encodePng(source));

    final result = await ImageOptimizer.toJpegs(png, maxDimensions: const [1200, 600, 5000]);

    expect(result, isNotNull);
    final decoded = result!.map((bytes) => img.decodeJpg(bytes)!).toList();
    expect([decoded[0].width, decoded[0].height], [1200, 800]);
    expect([decoded[1].width, decoded[1].height], [600, 400]);
    expect([decoded[2].width, decoded[2].height], [3000, 2000]); // not upscaled
    expect(result[0].length, lessThan(png.length));
  });

  test('keeps portrait orientation when fitting the longest side', () async {
    final source = img.Image(width: 800, height: 1600);
    final result = await ImageOptimizer.toJpegs(
      Uint8List.fromList(img.encodePng(source)),
      maxDimensions: const [600],
    );

    final decoded = img.decodeJpg(result!.single)!;
    expect([decoded.width, decoded.height], [300, 600]);
  });

  test('flattens transparent areas onto white instead of black', () async {
    final source = img.Image(width: 100, height: 100, numChannels: 4)..clear(img.ColorRgba8(0, 0, 0, 0));
    final result = await ImageOptimizer.toJpegs(
      Uint8List.fromList(img.encodePng(source)),
      maxDimensions: const [100],
    );

    final pixel = img.decodeJpg(result!.single)!.getPixel(50, 50);
    expect(pixel.r, greaterThan(245));
    expect(pixel.g, greaterThan(245));
    expect(pixel.b, greaterThan(245));
  });

  test('returns null for data it cannot decode', () async {
    final result = await ImageOptimizer.toJpegs(Uint8List.fromList([1, 2, 3, 4]), maxDimensions: const [600]);
    expect(result, isNull);
  });
}
