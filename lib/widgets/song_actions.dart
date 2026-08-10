import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/favorite_store.dart';
import '../data/song_editor.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
import '../services/song_service.dart';
import 'playlist_choice_sheet.dart';
import 'song_editor_dialog.dart';
import 'song_menu.dart';

Future<void> handleSongAction(
  BuildContext context,
  SongAction action,
  Song song, {
  VoidCallback? onChanged,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  switch (action) {
    case SongAction.playNext:
      SongService().playNext(song);
      messenger.showSnackBar(
        SnackBar(content: Text('"${song.title}" kommt als Nächstes')),
      );

    case SongAction.addToQueue:
      SongService().addToQueue(song);
      messenger.showSnackBar(
        SnackBar(content: Text('"${song.title}" zur Warteschlange')),
      );

    case SongAction.addToPlaylist:
      final playlist = await choosePlaylist(context);
      if (playlist == null) return;

      await PlaylistService().addToPlaylist(playlist.id, song);
      messenger.showSnackBar(
        SnackBar(content: Text('Zu "${playlist.title}" hinzugefügt')),
      );

    case SongAction.favorite:
      final added = await FavoriteStore.toggle(song.id);
      onChanged?.call();
      messenger.showSnackBar(
        SnackBar(
          content: Text(added ? 'Zu Favoriten' : 'Aus Favoriten entfernt'),
        ),
      );

    case SongAction.edit:
      final saved = await showSongEditor(context, song);
      if (!saved) return;

      await SongService().refresh();
      onChanged?.call();
      messenger.showSnackBar(
        const SnackBar(content: Text('Gespeichert')),
      );

    case SongAction.removeFile:
      final confirmed = await _confirmDelete(context, song);
      if (!confirmed) return;

      final deleted = await SongEditor.deleteFile(song);
      if (deleted) await SongService().refresh();
      onChanged?.call();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            deleted
                ? '"${song.title}" gelöscht'
                : '"${song.title}" konnte nicht gelöscht werden',
          ),
        ),
      );
  }
}

Future<bool> _confirmDelete(BuildContext context, Song song) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surfaceHi,
      title: const Text('Datei löschen?'),
      content: Text(
        '"${song.title}" wird endgültig von deinem Gerät entfernt.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('Löschen'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
