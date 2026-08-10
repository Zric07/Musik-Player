import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../data/favorite_store.dart';
import '../data/song_editor.dart';
import '../models/song.dart';

enum SongAction {
  playNext,
  addToQueue,
  addToPlaylist,
  favorite,
  edit,
  removeFile,
}

class SongMenu extends StatelessWidget {
  final Song song;
  final ValueChanged<SongAction> onSelected;
  final double size;

  const SongMenu({
    super.key,
    required this.song,
    required this.onSelected,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    final isFavorite = FavoriteStore.contains(song.id);

    return PopupMenuButton<SongAction>(
      tooltip: 'Optionen',
      icon: Icon(Icons.more_horiz_rounded, size: size),
      color: AppColors.surfaceTop,
      position: PopupMenuPosition.under,
      iconColor: AppColors.textFaint,
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: SongAction.favorite,
          child: _Entry(
            icon: isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: isFavorite ? 'Aus Favoriten' : 'Zu Favoriten',
            highlight: isFavorite,
          ),
        ),
        const PopupMenuItem(
          value: SongAction.playNext,
          child: _Entry(
            icon: Icons.playlist_play_rounded,
            label: 'Als Nächstes abspielen',
          ),
        ),
        const PopupMenuItem(
          value: SongAction.addToQueue,
          child: _Entry(
            icon: Icons.queue_music_rounded,
            label: 'Zur Warteschlange',
          ),
        ),
        const PopupMenuItem(
          value: SongAction.addToPlaylist,
          child: _Entry(
            icon: Icons.playlist_add_rounded,
            label: 'Zu Playlist hinzufügen',
          ),
        ),
        if (SongEditor.canEdit) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: SongAction.edit,
            child: _Entry(
              icon: Icons.edit_outlined,
              label: 'Bearbeiten',
            ),
          ),
          const PopupMenuItem(
            value: SongAction.removeFile,
            child: _Entry(
              icon: Icons.delete_outline_rounded,
              label: 'Löschen',
              danger: true,
            ),
          ),
        ],
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final bool highlight;

  const _Entry({
    super.key,
    required this.icon,
    required this.label,
    this.danger = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.danger
        : highlight
        ? AppColors.accent
        : AppColors.text;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(label, style: AppText.itemTitle.copyWith(color: color)),
      ],
    );
  }
}
