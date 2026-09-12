import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/localized_text.dart';
import '../../../../core/utils/responsive/breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_input_style.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// Owns the two controllers behind one admin-entered [LocalizedText] field
/// so the form's `initState`/`dispose`/submit each stay a single line per
/// field instead of two.
class BilingualController {
  BilingualController([LocalizedText? initial])
    : en = TextEditingController(text: initial?.en ?? ''),
      ja = TextEditingController(text: initial?.ja ?? '');

  final TextEditingController en;
  final TextEditingController ja;

  LocalizedText get value => LocalizedText(en: en.text.trim(), ja: ja.text.trim());

  void dispose() {
    en.dispose();
    ja.dispose();
  }
}

/// English + Japanese inputs for one field. English is required (the source
/// language, decision #1), Japanese optional — the customer app falls back
/// to English when it's blank. Side by side when there's room, stacked on a
/// phone. Each box is tagged `EN` / `JA` so the admin can tell them apart
/// regardless of which language the admin UI itself is in.
class BilingualTextField extends StatelessWidget {
  const BilingualTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.requiredError,
    this.maxLines = 1,
    this.radius = 14,
  });

  final BilingualController controller;

  /// Base hint, e.g. "Product name" — suffixed with the language per box.
  final String hintText;

  /// Validation message when the English box is left empty; `null` makes the
  /// whole field optional (a blank subcategory row is simply skipped).
  final String? requiredError;
  final int maxLines;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final en = TextFormField(
      controller: controller.en,
      maxLines: maxLines,
      decoration: _decoration('EN', 'admin.field_en'.tr(namedArgs: {'field': hintText})),
      validator: requiredError == null
          ? null
          : (value) => (value == null || value.trim().isEmpty) ? requiredError : null,
    );
    final ja = TextFormField(
      controller: controller.ja,
      maxLines: maxLines,
      decoration: _decoration('JA', 'admin.field_ja'.tr(namedArgs: {'field': hintText})),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.mobile) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: en),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: ja),
            ],
          );
        }
        return Column(children: [en, const SizedBox(height: AppSpacing.sm), ja]);
      },
    );
  }

  InputDecoration _decoration(String tag, String hint) {
    return AppInputStyle.decoration(
      hintText: hint,
      radius: radius,
      prefixIcon: _LanguageTag(tag),
    ).copyWith(
      // Keep the tag pinned to the top for multi-line boxes instead of
      // floating at the vertical centre of a tall description field.
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 0),
      alignLabelWithHint: true,
    );
  }
}

class _LanguageTag extends StatelessWidget {
  const _LanguageTag(this.tag);

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          tag,
          style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11),
        ),
      ),
    );
  }
}

/// Small "JA missing" marker for admin list rows — lets the admin see at a
/// glance which products/categories still need a Japanese name without
/// opening each one.
class MissingJaBadge extends StatelessWidget {
  const MissingJaBadge({super.key, required this.text});

  final LocalizedText text;

  @override
  Widget build(BuildContext context) {
    if (text.hasJa) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'admin.ja_missing'.tr(),
        style: AppTextStyles.caption.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
