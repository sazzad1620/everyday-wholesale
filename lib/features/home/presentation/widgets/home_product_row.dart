import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/responsive/breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/hover_lift.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../product/domain/entities/product_entity.dart';

const double _gap = AppSpacing.sm;
const double _rowTopPadding = 6; // room for a hovered card to lift
const double _rowBottomPadding = 10; // room for the card shadows
const double _desktopCardWidth = 190;

/// A titled row of product cards that scrolls sideways.
///
/// Phone: cards are sized so 2½ fit — the cut-off third card shows it
/// scrolls. Tablet/desktop: fixed-width cards plus ◀ ▶ buttons (a mouse has
/// no swipe) that appear only while there is more to see in that direction;
/// a mouse can also drag the row.
class HomeProductRow extends StatefulWidget {
  const HomeProductRow({
    super.key,
    required this.title,
    required this.products,
    required this.onProductTap,
    required this.onViewAll,
    this.endWithViewAllCard = false,
  });

  final String title;
  final List<ProductEntity> products;
  final ValueChanged<ProductEntity> onProductTap;
  final VoidCallback onViewAll;

  /// Adds a last "View all" card, for rows showing only the first products
  /// of a bigger set.
  final bool endWithViewAllCard;

  @override
  State<HomeProductRow> createState() => _HomeProductRowState();
}

class _HomeProductRowState extends State<HomeProductRow> {
  final ScrollController _controller = ScrollController();
  bool _canScrollBack = false;
  bool _canScrollForward = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onMetrics(ScrollMetrics metrics) {
    final back = metrics.pixels > 4;
    final forward = metrics.pixels < metrics.maxScrollExtent - 4;
    if (back != _canScrollBack || forward != _canScrollForward) {
      setState(() {
        _canScrollBack = back;
        _canScrollForward = forward;
      });
    }
    return false;
  }

  void _scrollBy(double delta) {
    _controller.animateTo(
      (_controller.offset + delta).clamp(0.0, _controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= AppBreakpoints.mobile;
        final cardWidth = wide
            ? _desktopCardWidth
            : math.max(124.0, (width - 2 * AppSpacing.md) / (width < 400 ? 2.3 : 2.5));
        final cardHeight = cardWidth + ProductCard.contentHeight(textScaler);
        final itemCount = widget.products.length + (widget.endWithViewAllCard ? 1 : 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title, style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  TextButton(onPressed: widget.onViewAll, child: Text('home.view_all'.tr())),
                ],
              ),
            ),
            SizedBox(
              height: cardHeight + _rowTopPadding + _rowBottomPadding,
              child: Stack(
                children: [
                  NotificationListener<ScrollMetricsNotification>(
                    onNotification: (n) => _onMetrics(n.metrics),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) => _onMetrics(n.metrics),
                      // Mouse drag scrolls the row on desktop web; the
                      // default scrollbar is off — the buttons are the cue.
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(
                          context,
                        ).copyWith(scrollbars: false, dragDevices: {...PointerDeviceKind.values}),
                        child: ListView.separated(
                          controller: _controller,
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            _rowTopPadding,
                            AppSpacing.md,
                            _rowBottomPadding,
                          ),
                          itemCount: itemCount,
                          separatorBuilder: (_, _) => const SizedBox(width: _gap),
                          itemBuilder: (context, index) {
                            if (index == widget.products.length) {
                              return _ViewAllCard(width: cardWidth * 0.78, height: cardHeight, onTap: widget.onViewAll);
                            }
                            final product = widget.products[index];
                            return SizedBox(
                              width: cardWidth,
                              height: cardHeight,
                              child: HoverLift(
                                child: ProductCard(product: product, onTap: () => widget.onProductTap(product)),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (wide) ...[
                    _ArrowButton(
                      alignment: Alignment.centerLeft,
                      icon: Icons.chevron_left_rounded,
                      visible: _canScrollBack,
                      top: _rowTopPadding + cardWidth / 2,
                      onTap: () => _scrollBy(-2 * (cardWidth + _gap)),
                    ),
                    _ArrowButton(
                      alignment: Alignment.centerRight,
                      icon: Icons.chevron_right_rounded,
                      visible: _canScrollForward,
                      top: _rowTopPadding + cardWidth / 2,
                      onTap: () => _scrollBy(2 * (cardWidth + _gap)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Round white button floating over the row's edge, level with the card
/// images. Fades out (and stops taking taps) when there is nothing further
/// in its direction.
class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.alignment,
    required this.icon,
    required this.visible,
    required this.top,
    required this.onTap,
  });

  final Alignment alignment;
  final IconData icon;
  final bool visible;
  final double top;
  final VoidCallback onTap;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top - _size / 2,
      left: alignment == Alignment.centerLeft ? AppSpacing.sm : null,
      right: alignment == Alignment.centerRight ? AppSpacing.sm : null,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: Material(
            color: AppColors.surface,
            elevation: 3,
            shadowColor: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: _size,
                height: _size,
                child: Icon(icon, color: AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Last card of a row that shows only the first products of a category.
class _ViewAllCard extends StatelessWidget {
  const _ViewAllCard({required this.width, required this.height, required this.onTap});

  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: HoverLift(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: Text(
                        'home.view_all'.tr(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
