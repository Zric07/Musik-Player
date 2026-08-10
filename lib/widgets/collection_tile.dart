import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/formatting.dart';
import '../models/collection.dart';
import 'color_tile.dart';
import 'hoverable.dart';

class CollectionTile extends StatelessWidget {
  final Collection collection;
  final IconData icon;
  final VoidCallback onTap;

  const CollectionTile({
    super.key,
    required this.collection,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hoverable(
      onTap: onTap,
      builder: (context, hovered) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            color: hovered ? AppColors.surfaceHi : Colors.transparent,
          ),
          child: Row(
            children: [
              ColorTile(seed: collection.coverKey, icon: icon, size: 50),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      collection.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.itemTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${collection.subtitle} · '
                      '${songCountLabel(collection.songs.length)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.itemSubtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
