import 'package:flutter/widgets.dart';

/// `Image.frameBuilder` that fades a network image in once its first frame
/// is decoded, instead of it popping in over the placeholder. Images that
/// are already in memory (e.g. revisiting a page) appear instantly.
Widget imageFadeIn(BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
  if (wasSynchronouslyLoaded) return child;
  return AnimatedOpacity(
    opacity: frame == null ? 0 : 1,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
    child: child,
  );
}
