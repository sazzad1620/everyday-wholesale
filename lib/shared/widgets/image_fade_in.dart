import 'package:flutter/widgets.dart';

/// `Image.frameBuilder` for every network photo: a soft neutral shimmer on the
/// (transparent) tile while the photo downloads, then the photo fades in over
/// it once its first frame is decoded. Images that are already in memory
/// (e.g. revisiting a page) appear instantly.
Widget imageFadeIn(BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
  if (wasSynchronouslyLoaded) return child;
  return Stack(
    fit: StackFit.passthrough,
    children: [
      Positioned.fill(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: frame == null ? const ImageShimmer() : const SizedBox.expand(),
        ),
      ),
      AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: child,
      ),
    ],
  );
}

/// The loading state of an image. Fills whatever box it is given; the band
/// always travels left to right.
///
/// [fill] `true` (banners, category tiles): a faint grey tile with a lighter
/// band sweeping over it (1.6 s). `false` (product photos on white cards): no
/// grey at all — the tile stays white and a wide, tilted, very soft glow
/// (about 5% black at its centre, 2.2 s, eased) drifts across it, so there is
/// no hard stripe and the card still reads as one white tile.
class ImageShimmer extends StatefulWidget {
  const ImageShimmer({super.key, this.strength = 1, this.fill = true});

  /// Scales how dark the grey is (1 = default, lower = softer).
  final double strength;

  final bool fill;

  @override
  State<ImageShimmer> createState() => _ImageShimmerState();
}

class _ImageShimmerState extends State<ImageShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: widget.fill ? 1600 : 2200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static Color _black(double alpha) => Color.fromRGBO(0, 0, 0, alpha);

  @override
  Widget build(BuildContext context) {
    final k = widget.strength;
    final fill = widget.fill;
    // `SizedBox.expand`: inside the `AnimatedSwitcher` above this gets *loose*
    // constraints, and a childless `DecoratedBox` would shrink to 0 × 0 and
    // paint nothing.
    final shimmer = SizedBox.expand(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = fill ? _controller.value : Curves.easeInOut.transform(_controller.value);
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: fill
                      ? [_black(0.04 * k), _black(0.09 * k), _black(0.04 * k)]
                      : [_black(0), _black(0.026 * k), _black(0.05 * k), _black(0.026 * k), _black(0)],
                  stops: fill ? const [0.2, 0.5, 0.8] : const [0.0, 0.25, 0.5, 0.75, 1.0],
                  transform: _SlideGradient(
                    fill ? -1.0 + 2.0 * t : -1.1 + 2.2 * t,
                    tilt: fill ? 0 : 0.31, // about 18 degrees
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    if (fill) return shimmer;
    // The glow dissolves toward the bottom, so it never ends in a hard line
    // where the photo area meets the name and price on a white card.
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(bounds),
      child: shimmer,
    );
  }
}

/// Slides a gradient horizontally by [fraction] of the box width, after
/// tilting it by [tilt] radians around the box centre.
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.fraction, {this.tilt = 0});

  final double fraction;
  final double tilt;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final centre = bounds.center;
    return Matrix4.identity()
      ..translateByDouble(centre.dx, centre.dy, 0, 1)
      ..rotateZ(tilt)
      ..translateByDouble(-centre.dx, -centre.dy, 0, 1)
      ..translateByDouble(bounds.width * fraction, 0, 0, 1);
  }
}
