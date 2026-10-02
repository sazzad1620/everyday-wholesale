import 'package:flutter/material.dart';

/// Lifts a card a few pixels while the mouse is over it — the usual website
/// hover cue for product/category tiles. Needed because those cards paint
/// opaque image/label backgrounds over their `InkWell`, which hides the
/// theme's hover highlight. Hover only fires for a mouse, so touch screens
/// (and the phone apps) are unaffected.
class HoverLift extends StatefulWidget {
  const HoverLift({super.key, required this.child});

  final Widget child;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        child: widget.child,
      ),
    );
  }
}
