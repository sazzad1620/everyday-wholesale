import 'package:flutter/material.dart';

import '../../core/utils/responsive/breakpoints.dart';

/// Marks a page's top-level scrollable (`ListView`, `GridView`, ...) as the
/// catalog content area, for tablet/desktop width.
///
/// Uncapped by default: [CategoryGrid]/[ProductGrid] already compute their
/// own column count from the width they're given (more columns, not bigger
/// cards, as that width grows), so a fixed ceiling here only starved them of
/// space and left a dead gutter down the right side of wide/ultra-wide
/// windows instead of letting the catalog use the screen. Pass [maxWidth]
/// only where a page genuinely wants a reading-width cap (e.g. a page of
/// prose); no current page does.
class ResponsiveContentContainer extends StatelessWidget {
  const ResponsiveContentContainer({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final cap = maxWidth;
    if (cap == null) return child;

    final width = MediaQuery.sizeOf(context).width;
    if (width < AppBreakpoints.mobile) return child;

    return Center(
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: cap), child: child),
    );
  }
}
