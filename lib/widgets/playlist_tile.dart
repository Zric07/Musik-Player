import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/formatting.dart';
import '../models/playlist.dart';
import 'hoverable.dart';
import 'playlist_cover.dart';

class PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final Widget? trailing;

  const PlaylistTile({
    super.key,
    required this.playlist,
    required this.onTap,
    this.trailing,
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
              PlaylistCover(playlist: playlist, size: 50),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      playlist.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.itemTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Playlist · ${songCountLabel(playlist.songCount)}',
                      style: AppText.itemSubtitle,
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        );
      },
    );
  }
}
