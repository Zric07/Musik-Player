import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../models/song.dart';
import 'cover_source.dart';

class CoverArt extends StatelessWidget {
  final Song song;
  final double size;
  final double radius;

  const CoverArt({
    super.key,
    required this.song,
    this.size = 52,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    final provider = coverProvider(song.cover);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: provider == null
            ? _Fallback(song: song, size: size)
            : Image(
                image: provider,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _Fallback(song: song, size: size),
              ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final Song song;
  final double size;

  const _Fallback({super.key, required this.song, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forKey(song.id);

    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.tileGradient(color)),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: Colors.white.withValues(alpha: 0.85),
          size: size * 0.4,
        ),
      ),
    );
  }
}
