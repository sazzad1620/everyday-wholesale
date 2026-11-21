import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_input_style.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

class AppDropdownItem<T> {
  const AppDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// A `select` styled to match every other field in the app — same flat
/// rounded box as [AppInputStyle], normal (non-bold) text — instead of
/// stock `DropdownButtonFormField`, whose default text theme reads bold and
/// whose popup menu doesn't respect the field's own width or corner radius
/// (it stretches edge-to-edge on some layouts). The popup here is anchored
/// and width-matched to the field itself via [showMenu]'s `constraints`,
/// with the same rounded corners as the field.
///
/// A [FormField] under the hood, so it drops into an existing [Form] and
/// participates in `formKey.currentState!.validate()` exactly like
/// [TextFormField] does.
class AppDropdownField<T> extends FormField<T> {
  AppDropdownField({
    super.key,
    required this.items,
    super.initialValue,
    this.hintText,
    this.radius = AppInputStyle.radius,
    required this.onChanged,
    super.validator,
    this.searchable = false,
    this.searchHintText,
  }) : super(
         builder: (field) {
           return _AppDropdownFieldView<T>(
             items: items,
             value: field.value,
             hintText: hintText,
             radius: radius,
             errorText: field.errorText,
             searchable: searchable,
             searchHintText: searchHintText,
             onChanged: (value) {
               field.didChange(value);
               onChanged(value);
             },
           );
         },
       );

  final List<AppDropdownItem<T>> items;
  final String? hintText;
  final double radius;
  final ValueChanged<T?> onChanged;

  /// Shows a filter box above the options instead of a bare list — for a
  /// list too long to scan by scrolling alone (e.g. the ~195-entry country
  /// picker). Leave off for short lists, where it'd just be clutter.
  final bool searchable;
  final String? searchHintText;
}

class _AppDropdownFieldView<T> extends StatefulWidget {
  const _AppDropdownFieldView({
    super.key,
    required this.items,
    required this.value,
    required this.hintText,
    required this.radius,
    required this.errorText,
    required this.onChanged,
    required this.searchable,
    required this.searchHintText,
  });

  final List<AppDropdownItem<T>> items;
  final T? value;
  final String? hintText;
  final double radius;
  final String? errorText;
  final ValueChanged<T?> onChanged;
  final bool searchable;
  final String? searchHintText;

  @override
  State<_AppDropdownFieldView<T>> createState() => _AppDropdownFieldViewState<T>();
}

class _AppDropdownFieldViewState<T> extends State<_AppDropdownFieldView<T>> {
  final GlobalKey _fieldKey = GlobalKey();

  Future<void> _openMenu() async {
    final T? selected;
    if (widget.searchable) {
      // A modal bottom sheet, not a `showMenu` popup: that popup's position
      // is computed once, up front, from the field's spot in the page as it
      // looks *before* the keyboard opens — a fixed `RelativeRect` that
      // doesn't adjust when the keyboard then shows and the page resizes
      // under it, which is what made the whole thing visibly jump/overshoot
      // once typing opened the keyboard. A bottom sheet manages its own
      // keyboard-aware layout instead of being anchored to a stale rect.
      selected = await showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(widget.radius)),
        ),
        builder: (sheetContext) => _SearchableSheetContent<T>(
          items: widget.items,
          value: widget.value,
          searchHintText: widget.searchHintText,
        ),
      );
    } else {
      final button = _fieldKey.currentContext!.findRenderObject()! as RenderBox;
      final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
      final position = RelativeRect.fromRect(
        Rect.fromPoints(
          button.localToGlobal(Offset(0, button.size.height), ancestor: overlay),
          button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
        ),
        Offset.zero & overlay.size,
      );
      selected = await showMenu<T>(
        context: context,
        position: position,
        // Forces the popup to exactly match the field's width instead of
        // sizing to content (which is what let it stretch full-screen-wide).
        constraints: BoxConstraints.tightFor(width: button.size.width),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.radius)),
        color: AppColors.surface,
        items: [
          for (final item in widget.items)
            PopupMenuItem<T>(
              value: item.value,
              child: Text(
                item.label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: item.value == widget.value ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: item.value == widget.value ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
        ],
      );
    }

    if (selected != null) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    String? selectedLabel;
    for (final item in widget.items) {
      if (item.value == widget.value) {
        selectedLabel = item.label;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: _fieldKey,
          decoration: AppInputStyle.boxDecoration(radius: widget.radius),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openMenu,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedLabel ?? widget.hintText ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: selectedLabel == null ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: AppSpacing.md),
            child: Text(widget.errorText!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
          ),
      ],
    );
  }
}

/// The sheet content for a [AppDropdownField.searchable] field — a drag
/// handle, a filter box, and the (filtered) option list, each row popping
/// the sheet with its own value. Matching only the *start* of each label
/// (not "contains") keeps it predictable for an alphabetical list: typing
/// "ban" jumps to "Bangladesh" and stays there, rather than also pulling in
/// every label that happens to contain "ban" somewhere in the middle
/// (Al**ban**ia, Le**ban**on, ...).
class _SearchableSheetContent<T> extends StatefulWidget {
  const _SearchableSheetContent({required this.items, required this.value, required this.searchHintText});

  final List<AppDropdownItem<T>> items;
  final T? value;
  final String? searchHintText;

  @override
  State<_SearchableSheetContent<T>> createState() => _SearchableSheetContentState<T>();
}

class _SearchableSheetContentState<T> extends State<_SearchableSheetContent<T>> {
  late List<AppDropdownItem<T>> _filtered = widget.items;

  void _onQueryChanged(String query) {
    final normalized = query.trim().toLowerCase();
    setState(() {
      _filtered = normalized.isEmpty
          ? widget.items
          : widget.items.where((item) => item.label.toLowerCase().startsWith(normalized)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.75;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: _DragHandle(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: TextField(
                autofocus: true,
                onChanged: _onQueryChanged,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.searchHintText,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text('search.empty_title'.tr(), style: AppTextStyles.body),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final item = _filtered[index];
                        final selected = item.value == widget.value;
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(item.value),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            child: Text(
                              item.label,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                color: selected ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
