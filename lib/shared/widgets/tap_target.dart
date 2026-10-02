import 'package:flutter/material.dart';

/// A plain tap area (text links, custom cards) that also shows the hand
/// cursor on web/desktop — a bare [GestureDetector] shows the text cursor,
/// so the link doesn't look clickable under a mouse. Disabled ([onTap] is
/// null) keeps the normal cursor. For Material-styled tappables use
/// `InkWell`/buttons, which handle the cursor themselves.
class TapTarget extends StatelessWidget {
  const TapTarget({super.key, required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}
