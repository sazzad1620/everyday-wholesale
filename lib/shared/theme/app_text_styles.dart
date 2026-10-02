import 'package:flutter/material.dart';

/// Sizes tuned for Plus Jakarta Sans (the app's body font), which reads a
/// little larger than Roboto at the same point size: section titles at 17
/// instead of 18 and page headlines at 22 instead of 24 keep phone screens
/// from feeling oversized, while body text stays at a comfortable 14.
abstract final class AppTextStyles {
  static const TextStyle headline = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.25);
  static const TextStyle title = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3);
  static const TextStyle body = TextStyle(fontSize: 14, fontWeight: FontWeight.normal);
  static const TextStyle caption = TextStyle(fontSize: 12, fontWeight: FontWeight.normal);
}
