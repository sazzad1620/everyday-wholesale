import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The app's one search box — the storefront header's product search and the
/// admin's product list use this same widget, so they always look and behave
/// alike: a soft grey, fully rounded field with a search icon on the left,
/// a clear (×) button once something is typed, and a green outline while it
/// has focus. (It used to be a grey pill with a small green circle bolted
/// onto the right in the storefront and a different, plain box in the admin.)
///
/// Purely the field: what searching *does* (a dropdown, filtering a list) is
/// up to the caller via [onChanged]. Clearing calls `onChanged('')`, so the
/// caller handles "cleared" exactly like "typed nothing".
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.focusNode,
    this.fieldKey,
    this.clearTooltip,
  });

  final TextEditingController controller;
  /// Defaults to the app-wide "Search for products..." (`search.hint`), so
  /// every place that uses this box says the same thing; pass one only for a
  /// box that searches something else.
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;

  /// Pass one to control/observe focus from outside; otherwise the field
  /// owns its own.
  final FocusNode? focusNode;

  /// Attached to the visible box itself, for callers that anchor something
  /// (a results dropdown) to its exact size and position.
  final Key? fieldKey;

  /// Accessibility label of the clear button; defaults to `search.clear`.
  final String? clearTooltip;

  /// Fixed so every search box in the app is the same height (and comfortably
  /// tappable on a phone).
  static const double height = 44;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  FocusNode? _ownFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void dispose() {
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged?.call('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _focusNode,
      builder: (context, _) {
        final focused = _focusNode.hasFocus;
        return AnimatedContainer(
          key: widget.fieldKey,
          duration: const Duration(milliseconds: 150),
          height: AppSearchField.height,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSearchField.height / 2),
            // Same width focused or not, so the text never shifts when the
            // outline appears.
            border: Border.all(color: focused ? AppColors.primary : Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: focused ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  onTap: widget.onTap,
                  onSubmitted: widget.onSubmitted,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: widget.hintText ?? 'search.hint'.tr(),
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox(width: 14);
                  return Padding(
                    padding: const EdgeInsets.only(left: 4, right: 8),
                    child: Tooltip(
                      message: widget.clearTooltip ?? 'search.clear'.tr(),
                      child: InkResponse(
                        onTap: _clear,
                        radius: 18,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.textSecondary.withValues(alpha: 0.18),
                          ),
                          child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
