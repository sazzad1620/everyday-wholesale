import 'package:flutter/material.dart';

import '../../../../core/utils/responsive/breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/auto_slide_carousel.dart';
import '../../../../shared/widgets/image_fade_in.dart';
import '../../domain/entities/promo_banner_entity.dart';

/// Every banner slot has this shape (12:5, e.g. the 4800×2000 artwork the
/// store uses); uploads are cropped to it with `BoxFit.cover`, so the admin
/// Banners page recommends a size in this ratio.
const double bannerAspectRatio = 12 / 5;

const double _gap = 12;
const double _radius = 20;

/// Admin-managed, auto-rotating home banners. Phones show one banner at a
/// time; wider screens show the current banner plus a faded peek of the
/// next one, so it's obvious there's more to see. With no banners uploaded
/// the carousel takes up no space at all.
class HomePromoCarousel extends StatefulWidget {
  const HomePromoCarousel({super.key, required this.banners});

  final List<PromoBannerEntity> banners;

  @override
  State<HomePromoCarousel> createState() => _HomePromoCarouselState();
}

class _HomePromoCarouselState extends State<HomePromoCarousel> {
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The first banner loads as it's drawn; the rest are fetched in the
    // background right away, so auto-play never slides to a blank one.
    if (_precached) return;
    _precached = true;
    for (final banner in widget.banners.skip(1)) {
      precacheImage(NetworkImage(banner.imageUrl), context, onError: (_, _) {});
    }
  }

  /// Share of the width one banner takes: the rest is the next banner's peek.
  static double _viewportFraction(double width) {
    if (width < AppBreakpoints.mobile) return 1;
    if (width < AppBreakpoints.tablet) return 0.86;
    return 0.74;
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    // Each slide carries half the gap on either side, so the outer padding
    // is trimmed by the same amount to keep the banner edges aligned with
    // the content below it.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md - _gap / 2),
      child: AutoSlideCarousel(
        itemCount: banners.length,
        aspectRatio: bannerAspectRatio,
        viewportFraction: _viewportFraction,
        itemSpacing: _gap,
        arrowsMinWidth: AppBreakpoints.mobile,
        itemBuilder: (context, index, isActive) => _BannerSlide(banner: banners[index], isActive: isActive),
      ),
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.banner, required this.isActive});

  final PromoBannerEntity banner;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    // The peeking neighbour is dimmed so the current banner reads as the
    // focus; on phones only one banner is ever fully in view anyway.
    return AnimatedOpacity(
      opacity: isActive ? 1 : 0.55,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: ColoredBox(
          color: AppColors.primary.withValues(alpha: 0.06),
          child: Image.network(
            banner.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            frameBuilder: imageFadeIn,
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.image_outlined, size: 40, color: Colors.black26)),
          ),
        ),
      ),
    );
  }
}
