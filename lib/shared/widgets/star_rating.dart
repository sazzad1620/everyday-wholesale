import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Renders a 0–5 rating as 5 stars (filled / half / outline). Used for real
/// product ratings — [ProductEntity.rating] is derived from its reviews.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 15, this.color});

  final double rating;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? AppColors.secondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final threshold = index + 1;
        IconData icon;
        if (rating >= threshold) {
          icon = Icons.star_rounded;
        } else if (rating >= threshold - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(icon, size: size, color: starColor);
      }),
    );
  }
}
