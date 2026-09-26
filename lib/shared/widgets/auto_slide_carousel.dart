import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Looping, auto-advancing slider shared by the home banners and the
/// product photo gallery, so both behave the same everywhere:
/// - slides forward on its own every [autoPlayInterval], pausing while the
///   pointer hovers it or the user is dragging;
/// - swipe on touch, click-and-drag with a mouse (Flutter web ignores mouse
///   drags on a `PageView` by default), hover arrows on wide screens, and
///   clickable dots.
///
/// Looping uses an unbounded `PageView` (index modulo [itemCount]) so
/// auto-play always slides forward instead of rewinding to the first item.
/// With a single item it's just that item — no dots, arrows or timer.
class AutoSlideCarousel extends StatefulWidget {
  const AutoSlideCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.aspectRatio,
    this.viewportFraction,
    this.itemSpacing = 0,
    this.viewportRadius,
    this.arrowsMinWidth = 0,
    this.autoPlayInterval = const Duration(seconds: 5),
  });

  final int itemCount;

  /// [isActive] is true for the slide currently in focus — e.g. to dim a
  /// peeking neighbour.
  final Widget Function(BuildContext context, int index, bool isActive) itemBuilder;

  /// Width ÷ height of one slide (excluding [itemSpacing]).
  final double aspectRatio;

  /// Share of the carousel's width one slide takes, by that width; the rest
  /// is a peek of the next slide. Defaults to one full-width slide. Always 1
  /// when there's only one item.
  final double Function(double width)? viewportFraction;

  /// Horizontal gap between slides — each slide is inset by half of it on
  /// both sides.
  final double itemSpacing;

  /// Clips the slide area (not the dots) to this shape.
  final BorderRadius? viewportRadius;

  /// Hover arrows only appear at or above this carousel width.
  final double arrowsMinWidth;

  final Duration autoPlayInterval;

  @override
  State<AutoSlideCarousel> createState() => _AutoSlideCarouselState();
}

const Duration _slideDuration = Duration(milliseconds: 700);

class _AutoSlideCarouselState extends State<AutoSlideCarousel> {
  PageController? _controller;
  Timer? _timer;
  bool _isHovering = false;
  bool _isDragging = false;

  /// Absolute page in the unbounded `PageView` — starts far from 0 so the
  /// user can also go backwards from the first item.
  late int _page = _startPage;

  int get _count => widget.itemCount;
  bool get _loops => _count > 1;
  int get _startPage => _loops ? _count * 1000 : 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant AutoSlideCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != _count) {
      _page = _startPage;
      _controller?.dispose();
      _controller = null;
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_loops) return;
    _timer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (_isHovering || _isDragging) return;
      _goTo(_page + 1);
    });
  }

  void _goTo(int page) {
    final controller = _controller;
    if (controller == null || !controller.hasClients) return;
    controller.animateToPage(page, duration: _slideDuration, curve: Curves.easeInOutCubic);
  }

  void _step(int delta) {
    _goTo(_page + delta);
    _restartTimer();
  }

  /// Nearest absolute page showing item [index], so tapping a dot never
  /// spins through a long run of items.
  void _goToItem(int index) {
    var delta = index - _page % _count;
    if (delta > _count / 2) delta -= _count;
    if (delta < -_count / 2) delta += _count;
    _step(delta);
  }

  PageController _controllerFor(double fraction) {
    final existing = _controller;
    if (existing != null && existing.viewportFraction == fraction) return existing;
    // Resizing across a breakpoint can change the fraction, which a
    // `PageController` can't change in place — swap it, keeping the page.
    // The old one is still attached until this frame rebuilds, so it's
    // disposed afterwards.
    if (existing != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => existing.dispose());
    }
    return _controller = PageController(viewportFraction: fraction, initialPage: _page);
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification && notification.dragDetails != null) {
      _isDragging = true;
    } else if (notification is ScrollEndNotification && _isDragging) {
      _isDragging = false;
      _restartTimer();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fraction = _loops ? (widget.viewportFraction?.call(width) ?? 1) : 1.0;
        final height = (width * fraction - widget.itemSpacing) / widget.aspectRatio;
        final controller = _controllerFor(fraction);
        final showArrows = _loops && width >= widget.arrowsMinWidth;

        Widget slides = NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: PageView.builder(
              controller: controller,
              // The focused slide sits at the left edge, so any peek is
              // only on the right.
              padEnds: false,
              itemCount: _loops ? null : 1,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, page) => Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.itemSpacing / 2),
                child: widget.itemBuilder(context, page % _count, page == _page),
              ),
            ),
          ),
        );
        if (widget.viewportRadius != null) {
          slides = ClipRRect(borderRadius: widget.viewportRadius!, child: slides);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              child: SizedBox(
                height: height,
                child: Stack(
                  children: [
                    Positioned.fill(child: slides),
                    if (showArrows) ...[
                      _ArrowButton(
                        alignment: Alignment.centerLeft,
                        icon: Icons.chevron_left_rounded,
                        visible: _isHovering,
                        onTap: () => _step(-1),
                      ),
                      _ArrowButton(
                        alignment: Alignment.centerRight,
                        icon: Icons.chevron_right_rounded,
                        visible: _isHovering,
                        onTap: () => _step(1),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_loops) ...[
              const SizedBox(height: AppSpacing.sm),
              _Dots(count: _count, activeIndex: _page % _count, onTap: _goToItem),
            ],
          ],
        );
      },
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.alignment, required this.icon, required this.visible, required this.onTap});

  final Alignment alignment;
  final IconData icon;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !visible,
            child: Material(
              color: Colors.white.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(icon, size: 28, color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.activeIndex, required this.onTap});

  final int count;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
