import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Evens out product photos before they're optimized and uploaded, so every
/// product sits in its white tile with the same breathing room.
///
/// Admins upload packshots on pure white, off-white or light grey, with
/// anything from no margin to a lot of it. Two fixes, both for the common
/// "product on a light plain background" case:
///
///  1. the plain background connected to the photo's edges becomes pure white
///     (so a cream/grey background doesn't show as a faint box on the white
///     tile) — flood-filled from the edges, so white *inside* the product
///     (a label, a rice bowl) is never touched;
///  2. the empty margin around the product is trimmed off, so the tile's
///     uniform padding is the *only* margin.
///
/// Full-bleed photos (a lifestyle shot, a bag filling the frame, a dark or
/// busy background) are left exactly as they are — there is no plain
/// background to normalize, and cropping them would cut the product.
abstract final class ProductImageCleaner {
  /// Returns the cleaned photo as PNG bytes (lossless, so the optimizer's
  /// JPEG pass is the only lossy step), or `null` when nothing needed
  /// changing or the image can't be decoded — callers then use the original.
  static Future<Uint8List?> clean(Uint8List bytes) => compute(_cleanBytes, bytes);

  @visibleForTesting
  static img.Image? cleanImage(img.Image source) => _clean(source);
}

Uint8List? _cleanBytes(Uint8List bytes) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;
  final cleaned = _clean(img.bakeOrientation(decoded));
  return cleaned == null ? null : img.encodePng(cleaned);
}

// A pixel counts as "background" when every channel is within this of the
// estimated background colour. Wide enough for JPEG noise and a soft grey
// gradient, narrow enough to stop at the product's edge.
const int _tolerance = 26;

// The background must be light — darker plain backgrounds are a deliberate
// look (black studio shot), not something to turn white.
const int _minBackgroundBrightness = 205;

// Share of the photo's border that must look like the background for the
// photo to count as "a product on a plain background".
const double _minBorderMatch = 0.92;

// Anything darker than this on any channel is "product" when finding the
// crop box; the white-ish pixels left after the fill are margin.
const int _contentThreshold = 244;

img.Image? _clean(img.Image source) {
  final width = source.width;
  final height = source.height;
  if (width < 16 || height < 16) return null;

  // Transparent cut-outs: flatten onto white first (alpha → white).
  var base = source;
  if (base.hasAlpha) {
    final white = img.Image(width: width, height: height)..clear(img.ColorRgb8(255, 255, 255));
    base = img.compositeImage(white, base);
  }

  final rgb = base.getBytes(order: img.ChannelOrder.rgb);
  final background = _estimateBackground(rgb, width, height);
  if (background == null) return null;

  final filled = _floodFillToWhite(rgb, width, height, background);

  final box = _contentBox(rgb, width, height);
  if (box == null) return null; // all white — nothing to keep

  final margin = (0.01 * (width > height ? width : height)).round().clamp(2, 24);
  final left = (box.left - margin).clamp(0, width - 1);
  final top = (box.top - margin).clamp(0, height - 1);
  final right = (box.right + margin).clamp(left + 1, width - 1);
  final bottom = (box.bottom + margin).clamp(top + 1, height - 1);

  final cropW = right - left + 1;
  final cropH = bottom - top + 1;
  final alreadyTight = cropW >= width * 0.97 && cropH >= height * 0.97;
  if (filled == 0 && alreadyTight) return null;

  final whitened = img.Image.fromBytes(width: width, height: height, bytes: rgb.buffer, numChannels: 3);
  return alreadyTight ? whitened : img.copyCrop(whitened, x: left, y: top, width: cropW, height: cropH);
}

/// Average colour of the four corners if the photo's border is a plain light
/// colour, else `null` (full-bleed photo, dark or busy background).
List<int>? _estimateBackground(Uint8List rgb, int width, int height) {
  const patch = 6;
  var r = 0, g = 0, b = 0, n = 0;
  for (final cx in [0, width - patch]) {
    for (final cy in [0, height - patch]) {
      for (var y = cy; y < cy + patch; y++) {
        for (var x = cx; x < cx + patch; x++) {
          final i = (y * width + x) * 3;
          r += rgb[i];
          g += rgb[i + 1];
          b += rgb[i + 2];
          n++;
        }
      }
    }
  }
  final bg = [r ~/ n, g ~/ n, b ~/ n];
  if (bg.reduce((a, c) => a < c ? a : c) < _minBackgroundBrightness) return null;

  var sampled = 0, matched = 0;
  bool matches(int x, int y) {
    final i = (y * width + x) * 3;
    return (rgb[i] - bg[0]).abs() <= _tolerance &&
        (rgb[i + 1] - bg[1]).abs() <= _tolerance &&
        (rgb[i + 2] - bg[2]).abs() <= _tolerance;
  }

  for (var x = 0; x < width; x += 3) {
    sampled += 2;
    if (matches(x, 0)) matched++;
    if (matches(x, height - 1)) matched++;
  }
  for (var y = 0; y < height; y += 3) {
    sampled += 2;
    if (matches(0, y)) matched++;
    if (matches(width - 1, y)) matched++;
  }
  return matched / sampled >= _minBorderMatch ? bg : null;
}

/// Turns every background-coloured pixel connected to the border pure white.
/// Returns how many pixels changed.
int _floodFillToWhite(Uint8List rgb, int width, int height, List<int> bg) {
  final visited = Uint8List(width * height);
  final stack = <int>[];
  var changed = 0;

  bool isBackground(int p) {
    final i = p * 3;
    return (rgb[i] - bg[0]).abs() <= _tolerance &&
        (rgb[i + 1] - bg[1]).abs() <= _tolerance &&
        (rgb[i + 2] - bg[2]).abs() <= _tolerance;
  }

  void seed(int x, int y) {
    final p = y * width + x;
    if (visited[p] == 1 || !isBackground(p)) return;
    visited[p] = 1;
    stack.add(p);
  }

  for (var x = 0; x < width; x++) {
    seed(x, 0);
    seed(x, height - 1);
  }
  for (var y = 0; y < height; y++) {
    seed(0, y);
    seed(width - 1, y);
  }

  while (stack.isNotEmpty) {
    final p = stack.removeLast();
    final i = p * 3;
    if (rgb[i] != 255 || rgb[i + 1] != 255 || rgb[i + 2] != 255) {
      rgb[i] = 255;
      rgb[i + 1] = 255;
      rgb[i + 2] = 255;
      changed++;
    }
    final x = p % width;
    final y = p ~/ width;
    if (x > 0) _push(visited, stack, p - 1, rgb, bg);
    if (x < width - 1) _push(visited, stack, p + 1, rgb, bg);
    if (y > 0) _push(visited, stack, p - width, rgb, bg);
    if (y < height - 1) _push(visited, stack, p + width, rgb, bg);
  }
  return changed;
}

// Neighbours are tested against the *original* background colour but the
// pixel may already be white (filled earlier), so white counts as background
// too — it can only get there by being connected to the border.
void _push(Uint8List visited, List<int> stack, int p, Uint8List rgb, List<int> bg) {
  if (visited[p] == 1) return;
  final i = p * 3;
  final isBg =
      (rgb[i] - bg[0]).abs() <= _tolerance &&
      (rgb[i + 1] - bg[1]).abs() <= _tolerance &&
      (rgb[i + 2] - bg[2]).abs() <= _tolerance;
  if (!isBg) return;
  visited[p] = 1;
  stack.add(p);
}

({int left, int top, int right, int bottom})? _contentBox(Uint8List rgb, int width, int height) {
  var left = width, top = height, right = -1, bottom = -1;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 3;
      if (rgb[i] < _contentThreshold || rgb[i + 1] < _contentThreshold || rgb[i + 2] < _contentThreshold) {
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
  }
  return right < 0 ? null : (left: left, top: top, right: right, bottom: bottom);
}
