import 'package:flutter/material.dart';

import '../../../core/utils/responsive/breakpoints.dart';
import '../../../features/home/domain/entities/category_entity.dart';
import 'categories_cache.dart';
import 'desktop_sidebar.dart';

/// Wraps a page's content (everything below its [AppHeader], and below its
/// `BreadcrumbBar` where it has one) with the persistent [DesktopSidebar] at
/// width >= [AppBreakpoints.mobile] — a no-op below that.
///
/// Deliberately placed *inside* each page, below its own header, rather than
/// wrapping the whole page from the outside (as a shell chrome widget would)
/// — the header needs to span the full page width, and the sidebar must
/// start below it, not beside it.
class DesktopBody extends StatelessWidget {
  const DesktopBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;
    if (!isWide) return child;

    return FutureBuilder<List<CategoryEntity>>(
      future: cachedCategories(),
      builder: (context, snapshot) {
        return Row(
          children: [
            DesktopSidebar(categories: snapshot.data ?? const []),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
