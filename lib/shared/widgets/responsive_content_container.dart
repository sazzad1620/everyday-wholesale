import 'package:flutter/material.dart';

import '../../core/utils/responsive/breakpoints.dart';

/// Caps page content to a readable max width and centers it at
/// tablet/desktop widths, so grids and text don't stretch edge-to-edge on a
/// wide browser tab — a no-op below [AppBreakpoints.mobile], where pages
/// already size themselves for phone width.
///
/// Wrap a page's top-level scrollable (`ListView`, `GridView`, ...) with
/// this rather than adding max-width logic to each page individually.
class ResponsiveContentContainer extends StatelessWidget {
  const ResponsiveContentContainer({super.key, required this.child, this.maxWidth = 1280});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < AppBreakpoints.mobile) return child;

    return Center(
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}
