import 'package:flutter/material.dart';

import '../../../../core/utils/responsive/breakpoints.dart';
import 'desktop_account_nav.dart';

/// Wraps a page's content (everything below its [AppHeader], and below its
/// `TabBar` where it has one) with the persistent [DesktopAccountNav] at
/// width >= [AppBreakpoints.mobile] — a no-op below that.
///
/// Same "lives inside the page, below its own header" reasoning as
/// `DesktopBody` — see that widget's doc comment.
class DesktopAccountBody extends StatelessWidget {
  const DesktopAccountBody({super.key, required this.child, this.current});

  final Widget child;
  final AccountNavItem? current;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;
    if (!isWide) return child;

    return Row(
      children: [
        DesktopAccountNav(current: current),
        Expanded(child: child),
      ],
    );
  }
}
