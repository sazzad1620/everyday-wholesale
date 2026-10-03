import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_network_image.dart';

/// Wide (2:1) photo field — the shape an offer's banner actually has in the
/// notification and on the Offers page, so the admin sees roughly what
/// customers get instead of a cropped square. Purely presentational, like
/// [SingleImagePicker]: picking/uploading is driven by the owning form.
class BannerImagePicker extends StatelessWidget {
  const BannerImagePicker({
    super.key,
    required this.imageUrl,
    required this.isUploading,
    required this.onTap,
    required this.onRemove,
    required this.placeholder,
  });

  /// 2:1 — also what the notification's expanded banner is cropped to.
  static const double aspectRatio = 2;

  final String? imageUrl;
  final bool isUploading;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  /// Shown while no photo is picked, e.g. "Add a banner photo (optional)".
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Material(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: isUploading ? null : onTap,
                  child: isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : url == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.black38),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              placeholder,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      : AppNetworkImage(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.inputFill),
                        ),
                ),
              ),
              if (url != null && !isUploading)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onRemove,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
