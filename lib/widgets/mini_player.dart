import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../core/formatting.dart';
import '../core/responsive.dart';
import '../models/song.dart';
import '../services/song_service.dart';
import 'cover_art.dart';
import 'gradient_button.dart';
import 'hoverable.dart';

class MiniPlayer extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final bool hasNext;
  final bool hasPrev;

  const MiniPlayer({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onOpen,
    required this.onToggle,
    required this.onNext,
    required this.onPrev,
    required this.hasNext,
    required this.hasPrev,
  });

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isDesktop(context);

    if (wide) {
      return Container(
        height: 82,
        decoration: const BoxDecoration(
          color: AppColors.sidebar,
          border: Border(top: BorderSide(color: AppColors.hairline)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            Expanded(flex: 3, child: _Meta(song: song, onOpen: onOpen)),
            Expanded(
              flex: 4,
              child: _WideControls(
                isPlaying: isPlaying,
                hasNext: hasNext,
                hasPrev: hasPrev,
                onToggle: onToggle,
                onNext: onNext,
                onPrev: onPrev,
              ),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerRight,
                child: SoftIconButton(
                  icon: Icons.open_in_full_rounded,
                  tooltip: 'Player öffnen',
                  onPressed: onOpen,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final seed = AppColors.forKey(song.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            seed.withValues(alpha: 0.30),
            AppColors.surfaceHi,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: AppSpacing.miniPlayerHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(child: _Meta(song: song, onOpen: onOpen)),
                    IconButton(
                      onPressed: onToggle,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 30,
                      ),
                      color: AppColors.text,
                    ),
                  ],
                ),
              ),
            ),
            const _ThinProgress(),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final Song song;
  final VoidCallback onOpen;

  const _Meta({super.key, required this.song, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Hoverable(
      onTap: onOpen,
      builder: (context, hovered) => Row(
        children: [
          CoverArt(song: song, size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.itemTitle.copyWith(
                    fontSize: 14,
                    decoration: hovered ? TextDecoration.underline : null,
                    decorationColor: AppColors.textDim,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.itemSubtitle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WideControls extends StatelessWidget {
  final bool isPlaying;
  final bool hasNext;
  final bool hasPrev;
  final VoidCallback onToggle;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const _WideControls({
    super.key,
    required this.isPlaying,
    required this.hasNext,
    required this.hasPrev,
    required this.onToggle,
    required this.onNext,
    required this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SoftIconButton(
              icon: Icons.skip_previous_rounded,
              onPressed: hasPrev ? onPrev : null,
              size: 36,
            ),
            const SizedBox(width: AppSpacing.md),
            _WhitePlayButton(isPlaying: isPlaying, onPressed: onToggle),
            const SizedBox(width: AppSpacing.md),
            SoftIconButton(
              icon: Icons.skip_next_rounded,
              onPressed: hasNext ? onNext : null,
              size: 36,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const _ScrubBar(),
      ],
    );
  }
}

class _WhitePlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _WhitePlayButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Hoverable(
      onTap: onPressed,
      builder: (context, hovered) {
        return AnimatedScale(
          scale: hovered ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.text,
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 22,
              color: AppColors.bg,
            ),
          ),
        );
      },
    );
  }
}

class _ScrubBar extends StatelessWidget {
  const _ScrubBar({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SongService();

    return StreamBuilder<Duration>(
      stream: service.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = service.duration ?? Duration.zero;
        final progress = total.inMilliseconds == 0
            ? 0.0
            : position.inMilliseconds / total.inMilliseconds;

        return Row(
          children: [
            Text(formatDuration(position), style: AppText.caption),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.24),
                  valueColor: const AlwaysStoppedAnimation(AppColors.text),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(formatDuration(total), style: AppText.caption),
          ],
        );
      },
    );
  }
}

class _ThinProgress extends StatelessWidget {
  const _ThinProgress({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SongService();

    return StreamBuilder<Duration>(
      stream: service.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = service.duration ?? Duration.zero;
        final progress = total.inMilliseconds == 0
            ? 0.0
            : position.inMilliseconds / total.inMilliseconds;

        return LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 2,
          backgroundColor: Colors.white.withValues(alpha: 0.14),
          valueColor: const AlwaysStoppedAnimation(AppColors.text),
        );
      },
    );
  }
}
