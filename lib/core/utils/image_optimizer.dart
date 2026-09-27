import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Resizes and re-encodes admin uploads before they go to Storage.
///
/// Admins upload whatever their phone/PC has — multi-megabyte PNGs and
/// full-resolution camera photos — and every customer then downloaded that
/// original for a 200px product card. Everything is re-encoded as JPEG at a
/// size that matches where it's actually shown, which typically takes a
/// 1–3 MB upload down to 50–250 KB.
///
/// Transparent images (product cut-outs) are flattened onto white first —
/// JPEG has no alpha channel, and white is the tile colour they sit on.
abstract final class ImageOptimizer {
  static const String contentType = 'image/jpeg';
  static const String fileExtension = 'jpg';

  /// Encodes [bytes] once per entry in [maxDimensions] (longest side, in
  /// px, never upscaled), decoding only once. Returns `null` if the format
  /// can't be decoded here (e.g. HEIC) — callers then upload the original.
  static Future<List<Uint8List>?> toJpegs(
    Uint8List bytes, {
    required List<int> maxDimensions,
    int quality = 80,
  }) => compute(_encode, _Job(bytes, maxDimensions, quality));
}

class _Job {
  const _Job(this.bytes, this.maxDimensions, this.quality);

  final Uint8List bytes;
  final List<int> maxDimensions;
  final int quality;
}

List<Uint8List>? _encode(_Job job) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(job.bytes);
  } catch (_) {
    // The decoders throw (rather than return null) on some corrupt or
    // unsupported inputs — treat both the same: "can't optimize this one".
    return null;
  }
  if (decoded == null) return null;
  // Phone photos store rotation in EXIF; bake it in, since the re-encoded
  // JPEG drops the EXIF block that told viewers to rotate it.
  final source = _flattenOntoWhite(img.bakeOrientation(decoded));

  return [
    for (final maxDimension in job.maxDimensions)
      img.encodeJpg(_fitWithin(source, maxDimension), quality: job.quality),
  ];
}

img.Image _fitWithin(img.Image image, int maxDimension) {
  if (image.width <= maxDimension && image.height <= maxDimension) return image;
  final landscape = image.width >= image.height;
  return img.copyResize(
    image,
    width: landscape ? maxDimension : null,
    height: landscape ? null : maxDimension,
    interpolation: img.Interpolation.average,
  );
}

img.Image _flattenOntoWhite(img.Image image) {
  if (!image.hasAlpha) return image;
  final background = img.Image(width: image.width, height: image.height)
    ..clear(img.ColorRgb8(255, 255, 255));
  return img.compositeImage(background, image);
}
