import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/playlist_service.dart';
import '../services/song_service.dart';
import 'playlist_choice_sheet.dart';
import 'song_menu.dart';

Future<void> handleSongAction(
  BuildContext context,
  SongAction action,
  Song song,
) async {
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
  }
}
