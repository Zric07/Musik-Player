import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../models/song.dart';
import 'cover_art.dart';
import 'hoverable.dart';
import 'playing_bars.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;
  final int? index;
  final Widget? trailing;

  const SongTile({
    super.key,
    required this.song,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
    this.index,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Hoverable(
      onTap: onTap,
      builder: (context, hovered) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            color: hovered ? AppColors.surfaceHi : Colors.transparent,
          ),
          child: Row(
            children: [
              _leading(hovered),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.itemTitle.copyWith(
                        color: isCurrent ? AppColors.accent : AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.itemSubtitle,
                    ),
                  ],
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: AppSpacing.sm),
                PlayingBars(animate: isPlaying),
              ],
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _leading(bool hovered) {
    if (index != null) {
      return SizedBox(
        width: 28,
        child: Center(
          child: hovered
              ? const Icon(
                  Icons.play_arrow_rounded,
                  size: 20,
                  color: AppColors.text,
                )
              : Text(
                  '${index! + 1}',
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(
                    color: isCurrent ? AppColors.accent : AppColors.textFaint,
                    fontSize: 14,
                  ),
                ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        CoverArt(song: song, size: 46),
        if (hovered)
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              isCurrent && isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 22,
              color: AppColors.text,
            ),
          ),
      ],
    );
  }
}
