import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Five tappable stars for submitting a whole 1–5 rating — the write-side
/// counterpart to the read-only [StarRating]. Tapping a star reports it
/// immediately via [onChanged] rather than needing a separate confirm step.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({super.key, this.rating = 0, required this.onChanged, this.size = 28, this.enabled = true});

  final int rating;
  final ValueChanged<int> onChanged;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          InkWell(
            onTap: enabled ? () => onChanged(star) : null,
            borderRadius: BorderRadius.circular(size),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                star <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                size: size,
                color: AppColors.secondary,
              ),
            ),
          ),
      ],
    );
  }
}
