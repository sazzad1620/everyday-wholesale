import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/product_image.dart';

/// Preview + camera-badge affordance for the product form's photo field.
/// Purely presentational — picking/uploading is driven by the form page
/// (mirrors how it already owns category/subcategory local state), so this
/// just renders whatever [imageUrl]/[isUploading] it's handed and reports
/// taps back via [onTap].
class ProductImagePicker extends StatelessWidget {
  const ProductImagePicker({
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
