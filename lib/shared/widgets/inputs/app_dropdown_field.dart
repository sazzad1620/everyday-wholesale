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
  }) : super(
         builder: (field) {
           return _AppDropdownFieldView<T>(
             items: items,
             value: field.value,
             hintText: hintText,
             radius: radius,
             errorText: field.errorText,
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
  });

  final List<AppDropdownItem<T>> items;
  final T? value;
  final String? hintText;
  final double radius;
  final String? errorText;
  final ValueChanged<T?> onChanged;

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

    final selected = await showMenu<T>(
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
