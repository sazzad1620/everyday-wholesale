import 'package:flutter/material.dart';

/// One (hue, saturation) seed per rotation slot — the actual colors are all
/// derived from these by varying only lightness, so the tile background,
/// its border, and its label strip always stay in the same family without
/// needing three hand-picked colors per category.
const List<(double hue, double saturation)> _categorySeeds = [
  (140, 0.45), // mint
  (260, 0.35), // lavender
  (30, 0.55), // peach
  (205, 0.45), // sky blue
  (340, 0.45), // rose
  (48, 0.55), // butter yellow
  (175, 0.40), // seafoam
  (285, 0.35), // lilac
];

(double hue, double saturation) _seedFor(int index) => _categorySeeds[index % _categorySeeds.length];

/// Very light tile background.
Color categoryColorFor(int index) {
  final (hue, saturation) = _seedFor(index);
  return HSLColor.fromAHSL(1, hue, saturation, 0.975).toColor();
}

/// Soft border, a step darker than the tile — same hue, not too dark.
Color categoryBorderColorFor(int index) {
  final (hue, saturation) = _seedFor(index);
  return HSLColor.fromAHSL(1, hue, saturation, 0.88).toColor();
}

/// Label strip background, between the tile and the border in darkness.
Color categoryLabelColorFor(int index) {
  final (hue, saturation) = _seedFor(index);
  return HSLColor.fromAHSL(1, hue, saturation, 0.93).toColor();
}
