import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';

enum SongAction { playNext, addToQueue, addToPlaylist }

class SongMenu extends StatelessWidget {
  final ValueChanged<SongAction> onSelected;
  final double size;

  const SongMenu({super.key, required this.onSelected, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SongAction>(
      tooltip: 'Optionen',
      icon: Icon(Icons.more_horiz_rounded, size: size),
      color: AppColors.surfaceTop,
      position: PopupMenuPosition.under,
      iconColor: AppColors.textFaint,
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: SongAction.playNext,
          child: _Entry(
            icon: Icons.playlist_play_rounded,
            label: 'Als Nächstes abspielen',
          ),
        ),
        PopupMenuItem(
          value: SongAction.addToQueue,
          child: _Entry(
            icon: Icons.queue_music_rounded,
            label: 'Zur Warteschlange',
          ),
        ),
        PopupMenuItem(
          value: SongAction.addToPlaylist,
          child: _Entry(
            icon: Icons.playlist_add_rounded,
            label: 'Zu Playlist hinzufügen',
          ),
        ),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Entry({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.text),
        const SizedBox(width: 12),
        Text(label, style: AppText.itemTitle),
      ],
    );
  }
}
