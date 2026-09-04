import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/di/injection_container.dart';
import '../../../config/routes/route_paths.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/product/domain/entities/product_entity.dart';
import '../../../features/product/presentation/bloc/search_bloc.dart';
import '../../../features/product/presentation/bloc/search_event.dart';
import '../../../features/product/presentation/bloc/search_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_input_style.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../product_image.dart';

/// Lives inside [AppHeader]. Types directly into the bar; matches trickle in
/// as a dropdown card floating just below it (an [OverlayEntry] tracked via
/// [CompositedTransformFollower], not a separate page) — tapping a result
/// goes straight to its detail page and closes the dropdown.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({super.key});

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final SearchBloc _bloc = getIt<SearchBloc>();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  /// Anchored to the search box itself (not this whole widget) — reading the
  /// size from `context.findRenderObject()` here would return the outer
  /// [Padding]'s box instead, which is wider than the box the [LayerLink]
  /// actually tracks, and the dropdown would overflow past the field's edge.
  final GlobalKey _fieldKey = GlobalKey();

  /// Groups the field and the overlay dropdown as one region so a tap
  /// landing on a result row doesn't count as "outside" and close it —
  /// [TapRegion] only ignores taps between regions sharing the same id.
  final Object _regionGroupId = Object();

  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onChanged(String value) {
    _bloc.add(SearchQueryChanged(value));
    if (value.trim().isEmpty) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final box = _fieldKey.currentContext!.findRenderObject() as RenderBox;
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        width: box.size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, box.size.height + AppSpacing.xs),
          child: _SearchResultsCard(bloc: _bloc, groupId: _regionGroupId, onSelect: _onProductSelected),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    _overlayEntry = entry;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onProductSelected(ProductEntity product) {
    _removeOverlay();
    _focusNode.unfocus();
    _controller.clear();
    _bloc.add(const SearchQueryChanged(''));
    context.push(RoutePaths.productDetail(product.categoryId, product.id));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: TapRegion(
        groupId: _regionGroupId,
        onTapOutside: (_) => _removeOverlay(),
        child: CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            key: _fieldKey,
            decoration: AppInputStyle.boxDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onChanged,
                    onTap: () {
                      if (_controller.text.trim().isNotEmpty) _showOverlay();
                    },
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'home.search_hint'.tr(),
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                          onPressed: () => _onChanged(''),
                        ),
                ),
                Padding(
                  // Sized (and inset from the edge) to sit clearly inside the
                  // box's own fully-rounded corner instead of pushing past
                  // its curve — a circle this close to the box's own radius
                  // reads as part of the same shape rather than a separate,
                  // oversized button dropped on top of it.
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.search_rounded, color: Colors.white, size: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultsCard extends StatelessWidget {
  const _SearchResultsCard({required this.bloc, required this.groupId, required this.onSelect});

  final SearchBloc bloc;
  final Object groupId;
  final ValueChanged<ProductEntity> onSelect;

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: groupId,
      child: Material(
        color: AppColors.surface,
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: BlocBuilder<SearchBloc, SearchState>(
            bloc: bloc,
            builder: (context, state) {
              if (state.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              if (state.errorMessage != null) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(state.errorMessage!, style: AppTextStyles.body.copyWith(color: AppColors.error)),
                );
              }
              if (state.results.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'search.empty_title'.tr(),
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                itemCount: state.results.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.textSecondary.withValues(alpha: 0.1)),
                itemBuilder: (context, index) => _SearchResultTile(product: state.results[index], onTap: onSelect),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.product, required this.onTap});

  final ProductEntity product;
  final ValueChanged<ProductEntity> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(product),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 44, height: 44, child: ProductImage(imageUrl: product.imageUrl, padding: 0)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: AppTextStyles.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(formatYen(product.price), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
