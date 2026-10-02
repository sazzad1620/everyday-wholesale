import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/localized_text.dart';
import '../../../../core/utils/responsive/breakpoints.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../domain/entities/subcategory_entity.dart';
import 'home_category_strip.dart';

/// "All" plus one round picture chip per subcategory, above a category's
/// products. Tapping a chip filters the products in place; the chosen one is
/// highlighted. Phones get a sideways-scrolling row (that scrolls to keep the
/// chosen chip in view); wider screens wrap them onto as many lines as needed
/// so nothing hides off-screen where a mouse can't swipe.
class SubcategoryChipStrip extends StatefulWidget {
  const SubcategoryChipStrip({
    super.key,
    required this.subcategories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<SubcategoryEntity> subcategories;

  /// Null means "All".
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  State<SubcategoryChipStrip> createState() => _SubcategoryChipStripState();
}

class _SubcategoryChipStripState extends State<SubcategoryChipStrip> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected(animate: false));
  }

  @override
  void didUpdateWidget(SubcategoryChipStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) _scrollToSelected(animate: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Centres the chosen chip when it would otherwise sit off-screen (a deep
  /// link straight to the 7th subcategory, say).
  void _scrollToSelected({required bool animate}) {
    if (!_controller.hasClients) return;
    final index = widget.selectedId == null ? 0 : 1 + widget.subcategories.indexWhere((s) => s.id == widget.selectedId);
    if (index < 0) return;
    final viewport = _controller.position.viewportDimension;
    final pitch = categoryCirclePitch(viewport, widget.subcategories.length + 1);
    final target = (AppSpacing.md + index * pitch - (viewport - pitch) / 2).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    if (animate) {
      _controller.animateTo(target, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    } else {
      _controller.jumpTo(target);
    }
  }

  /// [width] is the slot width in the scrolling row; null keeps the default
  /// (wrapped layout).
  List<Widget> _items(BuildContext context, {double? width}) {
    return [
      CategoryCircleItem(
        width: width ?? CategoryCircleItem.defaultWidth,
        label: 'product.filter_all'.tr(),
        imageUrl: null,
        icon: Icons.apps_rounded,
        colorIndex: 0,
        selected: widget.selectedId == null,
        onTap: () => widget.onSelected(null),
      ),
      for (var i = 0; i < widget.subcategories.length; i++)
        CategoryCircleItem(
          width: width ?? CategoryCircleItem.defaultWidth,
          label: context.localized(widget.subcategories[i].name),
          imageUrl: widget.subcategories[i].imageUrl,
          colorIndex: i + 1,
          selected: widget.selectedId == widget.subcategories[i].id,
          onTap: () => widget.onSelected(widget.subcategories[i].id),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.sm, children: _items(context)),
      );
    }

    return SizedBox(
      height: categoryCircleRowHeight(MediaQuery.textScalerOf(context)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final items = _items(
            context,
            width: categoryCirclePitch(constraints.maxWidth, widget.subcategories.length + 1),
          );
          return ListView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
          );
        },
      ),
    );
  }
}
