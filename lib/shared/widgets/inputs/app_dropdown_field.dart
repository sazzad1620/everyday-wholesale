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
    final button = _fieldKey.currentContext!.findRenderObject()! as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(0, button.size.height), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final T? selected;
    if (widget.searchable) {
      // A single disabled item hosting its own stateful content: `enabled:
      // false` drops PopupMenuItem's own tap/ink handling (which would
      // otherwise swallow taps meant for the search field and option rows
      // inside it) while still letting that content render and respond to
      // its own gestures.
      selected = await showMenu<T>(
        context: context,
        position: position,
        constraints: BoxConstraints.tightFor(width: button.size.width),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.radius)),
        color: AppColors.surface,
        items: [
          PopupMenuItem<T>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: _SearchableMenuContent<T>(
              items: widget.items,
              value: widget.value,
              searchHintText: widget.searchHintText,
            ),
          ),
        ],
      );
    } else {
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

/// The popup content for a [AppDropdownField.searchable] field: a filter box
/// above a scrollable option list, both inside the one `enabled: false`
/// [PopupMenuItem] that hosts this (see `_openMenu`). Each row pops the menu
/// with its own value directly, same as tapping a plain [PopupMenuItem]
/// would.
class _SearchableMenuContent<T> extends StatefulWidget {
  const _SearchableMenuContent({required this.items, required this.value, required this.searchHintText});

  final List<AppDropdownItem<T>> items;
  final T? value;
  final String? searchHintText;

  @override
  State<_SearchableMenuContent<T>> createState() => _SearchableMenuContentState<T>();
}

class _SearchableMenuContentState<T> extends State<_SearchableMenuContent<T>> {
  late List<AppDropdownItem<T>> _filtered = widget.items;

  void _onQueryChanged(String query) {
    final normalized = query.trim().toLowerCase();
    setState(() {
      _filtered = normalized.isEmpty
          ? widget.items
          : widget.items.where((item) => item.label.toLowerCase().contains(normalized)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // The parent PopupMenuItem is `enabled: false` (see _openMenu) so it
    // doesn't swallow taps meant for the search box and option rows — but
    // that also merges a dimmed IconTheme (0.38 opacity) over this subtree,
    // which would fade the search icon below. Reset it back to full opacity.
    return IconTheme.merge(
      data: const IconThemeData(opacity: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, AppSpacing.xs),
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text('search.empty_title'.tr(), style: AppTextStyles.body),
                  )
                : ListView.builder(
                    shrinkWrap: true,
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
    );
  }
}
