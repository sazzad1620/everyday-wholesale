import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/product_image.dart';

/// Preview + camera-badge affordance for a single-photo field — categories
/// and subcategories still only ever get one photo each (unlike products,
/// which use [ProductImagePicker] for its up-to-5 gallery). Purely
/// presentational — picking/uploading is driven by the owning form, so this
/// just renders whatever [imageUrl]/[isUploading] it's handed and reports
/// taps back via [onTap].
class SingleImagePicker extends StatelessWidget {
  const SingleImagePicker({
    super.key,
    required this.imageUrl,
    required this.isUploading,
    required this.onTap,
    this.size = 140,
  });

  final String? imageUrl;
  final bool isUploading;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: isUploading
                ? const ColoredBox(
                    color: AppColors.inputFill,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : ProductImage(imageUrl: imageUrl),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isUploading ? null : onTap,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
