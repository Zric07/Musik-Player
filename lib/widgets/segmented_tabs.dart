import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import 'hoverable.dart';

class SegmentedTabs extends StatelessWidget {
  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const SegmentedTabs({
    super.key,
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final active = i == index;

          return Hoverable(
            onTap: () => onChanged(i),
            builder: (context, hovered) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.text
                      : hovered
                      ? AppColors.surfaceTop
                      : AppColors.surfaceHi,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  labels[i],
                  style: AppText.itemTitle.copyWith(
                    fontSize: 13.5,
                    color: active ? AppColors.bg : AppColors.text,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
