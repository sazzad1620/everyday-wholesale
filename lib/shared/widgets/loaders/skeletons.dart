import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/responsive/breakpoints.dart';
import '../../../features/home/presentation/widgets/category_card.dart';
import '../../../features/home/presentation/widgets/home_promo_carousel.dart' show bannerAspectRatio;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../image_fade_in.dart';
import '../product_card.dart';
import '../responsive_content_container.dart';

/// Skeletons: grey stand-ins with the shape of the content that is loading,
/// used instead of a spinner wherever a page or list is waiting for data.
/// They use the same soft shimmer as image loading ([ImageShimmer]), so the
/// whole app loads in one visual language. Spinners stay for button actions
/// and short blocking steps.
///
/// All of these ignore taps, are not scrollable and clip their own overflow, so
/// a page can drop one in where its content will appear.

/// A grey rounded block (a line of text, a thumbnail, a button…).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 12, this.radius = 6});

  /// A circle of the given [diameter].
  const SkeletonBox.circle({super.key, required double diameter}) : width = diameter, height = diameter, radius = diameter / 2;

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: const ImageShimmer()),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2))],
);

/// Same size and look as a [ProductCard], with the photo area glowing softly
/// and grey lines for the name, price and stars.
class SkeletonProductCard extends StatelessWidget {
  const SkeletonProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => DecoratedBox(
        decoration: _cardDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: constraints.maxWidth, width: double.infinity, child: const ImageShimmer(fill: false)),
              const Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.sm, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 11),
                    SizedBox(height: 6),
                    SkeletonBox(width: 70, height: 11),
                    SizedBox(height: 12),
                    SkeletonBox(width: 54, height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 80, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A product grid that is still loading — same columns and card size as
/// `ProductGrid`.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.rows = 2, this.padding = EdgeInsets.zero});

  final int rows;
  final EdgeInsets padding;

  static const double _maxCardWidth = 220; // keep equal to ProductGrid

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: padding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / _maxCardWidth).ceil().clamp(1, 999);
            final cardWidth = (constraints.maxWidth - (columns - 1) * AppSpacing.sm) / columns;
            return GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: columns * rows,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisExtent: cardWidth + ProductCard.contentHeight(MediaQuery.textScalerOf(context)),
              ),
              itemBuilder: (context, _) => const SkeletonProductCard(),
            );
          },
        ),
      ),
    );
  }
}

/// A titled, sideways row of product cards, like `HomeProductRow`.
class _SkeletonProductRow extends StatelessWidget {
  const _SkeletonProductRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= AppBreakpoints.mobile;
        final cardWidth = wide ? 190.0 : math.max(124.0, (width - 2 * AppSpacing.md) / (width < 400 ? 2.3 : 2.5));
        final cardHeight = cardWidth + ProductCard.contentHeight(MediaQuery.textScalerOf(context));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
              child: SkeletonBox(width: 150, height: 18),
            ),
            SizedBox(
              height: cardHeight + 16,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, AppSpacing.md, 10),
                child: Row(
                  children: [
                    for (var i = 0; i < 6; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      SizedBox(width: cardWidth, height: cardHeight, child: const SkeletonProductCard()),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The home page while it loads: banner, category pictures (phones), product rows.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;
    return IgnorePointer(
      child: ResponsiveContentContainer(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: AppSpacing.md),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: AspectRatio(
                aspectRatio: bannerAspectRatio,
                child: ClipRRect(borderRadius: BorderRadius.circular(16), child: const ImageShimmer()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (!wide) ...[
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: 6,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                  itemBuilder: (_, _) => const Column(
                    children: [SkeletonBox.circle(diameter: 64), SizedBox(height: 8), SkeletonBox(width: 56, height: 10)],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const _SkeletonProductRow(),
            const _SkeletonProductRow(),
          ],
        ),
      ),
    );
  }
}

/// The Category tab while it loads: a title and the grid of category tiles.
class CategoriesSkeleton extends StatelessWidget {
  const CategoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ResponsiveContentContainer(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: AppSpacing.md),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(alignment: Alignment.centerLeft, child: SkeletonBox(width: 130, height: 20)),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: categoryTileGridDelegate(
                  constraints.maxWidth - 2 * AppSpacing.md,
                  MediaQuery.textScalerOf(context),
                ),
                itemBuilder: (_, _) => const SkeletonBox(radius: 16, height: double.infinity),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A product detail page while it loads: photo, name, price and info tiles.
class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget photo() => AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(16), child: const ImageShimmer(fill: false)),
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(height: 22),
        const SizedBox(height: 8),
        const SkeletonBox(width: 180, height: 22),
        const SizedBox(height: AppSpacing.md),
        const SkeletonBox(width: 90, height: 24),
        const SizedBox(height: AppSpacing.md),
        const SkeletonBox(width: 150, height: 14),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              const Expanded(child: SkeletonBox(height: 72, radius: 14)),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonBox(height: 46, radius: 23),
      ],
    );

    return IgnorePointer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth >= 720
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The real page gives the photo about 40% of the width.
                          Expanded(flex: 2, child: photo()),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(flex: 3, child: info),
                        ],
                      )
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [photo(), const SizedBox(height: AppSpacing.md), info]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A vertical list of card-shaped placeholders: a [header] block of the given
/// height (a photo, say; none when 0) above [lines] grey text lines.
/// Used for offers, orders and reviews.
class CardListSkeleton extends StatelessWidget {
  const CardListSkeleton({super.key, this.count = 4, this.header = 0, this.lines = 3, this.maxWidth, this.padding});

  final int count;
  final double header;
  final int lines;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final list = ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => DecoratedBox(
        decoration: _cardDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (header > 0) SizedBox(height: header, width: double.infinity, child: const ImageShimmer()),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < lines; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      SkeletonBox(width: i == 0 ? 160 : (i == lines - 1 ? 110 : null), height: i == 0 ? 16 : 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return IgnorePointer(
      child: maxWidth == null ? list : Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth!), child: list)),
    );
  }
}
