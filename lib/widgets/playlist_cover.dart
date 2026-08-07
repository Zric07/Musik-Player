import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import 'cover_source.dart';

class PlaylistCover extends StatelessWidget {
  final Playlist playlist;
  final double size;
  final double radius;

  const PlaylistCover({
    super.key,
    required this.playlist,
    this.size = 52,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    final provider = coverProvider(playlist.cover);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: provider == null
            ? _Placeholder(size: size)
            : Image(
                image: provider,
                key: ValueKey(
                  '${playlist.cover}_${PlaylistService().coverRevision}',
                ),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _Placeholder(size: size),
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double size;

  const _Placeholder({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.coverEmpty),
      child: Center(
        child: Icon(
          Icons.queue_music_rounded,
          color: AppColors.textFaint,
          size: size * 0.4,
        ),
      ),
    );
  }
}
