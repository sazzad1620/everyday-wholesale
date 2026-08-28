import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/utils/category_icons.dart';

/// Grid of every icon in [categoryIcons] for the admin to pick a category's
/// [CategoryEntity.iconKey] from — avoids free-text icon-key entry, which
/// would silently fall back to the generic placeholder on any typo.
class IconPicker extends StatelessWidget {
  const IconPicker({super.key, required this.selectedKey, required this.onSelected});

  final String? selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final entry in categoryIcons.entries)
          _IconOption(
            icon: entry.value,
            isSelected: entry.key == selectedKey,
            onTap: () => onSelected(entry.key),
          ),
      ],
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({required this.icon, required this.isSelected, required this.onTap});

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : AppColors.inputFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          child: Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondary, size: 24),
        ),
      ),
    );
  }
}
