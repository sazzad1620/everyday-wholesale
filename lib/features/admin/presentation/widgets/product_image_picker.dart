import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/product_image.dart';
import '../../../product/domain/entities/product_entity.dart';

/// Row of photo thumbnails + an add tile for the product form's photo field.
/// Purely presentational — picking/uploading is driven by the form page
/// (mirrors how it already owns category/subcategory local state), so this
/// just renders whatever [images]/[isUploading] it's handed and reports an
/// add tap via [onAdd] and a per-thumbnail removal via [onRemove]. The first
/// image is the product's primary photo — shown everywhere else in the app
/// (cards, search, order history) — so it's flagged "Main" here.
class ProductImagePicker extends StatelessWidget {
  const ProductImagePicker({
    super.key,
    required this.images,
    required this.isUploading,
    required this.onAdd,
    required this.onRemove,
    this.size = 100,
  });

  final List<String> images;
  final bool isUploading;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final double size;

  @override
  Widget build(BuildContext context) {
    final canAddMore = images.length < ProductEntity.maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('admin.product_photos_label'.tr(), style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: size + 12,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < images.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _ImageSlot(url: images[i], size: size, isMain: i == 0, onRemove: () => onRemove(i)),
                ),
              if (canAddMore) _AddSlot(size: size, isUploading: isUploading, onTap: isUploading ? null : onAdd),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'admin.product_photos_hint'.tr(
            namedArgs: {'count': '${images.length}', 'max': '${ProductEntity.maxImages}'},
          ),
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ImageSlot extends StatelessWidget {
  const _ImageSlot({required this.url, required this.size, required this.isMain, required this.onRemove});

  final String url;
  final double size;
  final bool isMain;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(borderRadius: BorderRadius.circular(16), child: ProductImage(imageUrl: url)),
          ),
          if (isMain)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'admin.product_photo_main_badge'.tr(),
                  style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          Positioned(
            right: -4,
            top: -4,
            child: Material(
              color: Colors.black.withValues(alpha: 0.6),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, color: Colors.white, size: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSlot extends StatelessWidget {
  const _AddSlot({required this.size, required this.isUploading, required this.onTap});

  final double size;
  final bool isUploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
          ),
          child: isUploading
              ? const Center(child: CircularProgressIndicator())
              : Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary, size: 28),
        ),
      ),
    );
  }
}
