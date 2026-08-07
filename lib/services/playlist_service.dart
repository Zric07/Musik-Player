import 'dart:typed_data';

import '../data/playlist_store.dart';
import '../models/playlist.dart';
import '../models/song.dart';

class PlaylistService {
  static final PlaylistService _instance = PlaylistService._();
  factory PlaylistService() => _instance;
  PlaylistService._();

  int _coverRevision = 0;

  int get coverRevision => _coverRevision;

  Future<void> createPlaylist(String title) => PlaylistStore.create(title);

  Future<void> renamePlaylist(String id, String title) =>
      PlaylistStore.rename(id, title);

  Future<void> deletePlaylist(String id) => PlaylistStore.delete(id);

  Future<List<Playlist>> getPlaylists() => PlaylistStore.all();

  Future<Playlist> getPlaylist(String id) => PlaylistStore.one(id);

  Future<void> addToPlaylist(String playlistId, Song song) =>
      PlaylistStore.addSong(playlistId, song.id);

  Future<void> removeSong(String playlistId, Song song) =>
      PlaylistStore.removeSong(playlistId, song.id);

  Future<void> setCover(String playlistId, Uint8List bytes) async {
    await PlaylistStore.saveCover(playlistId, bytes);
    _coverRevision++;
  }

  Future<void> clearCover(String playlistId) async {
    await PlaylistStore.deleteCover(playlistId);
    _coverRevision++;
  }
}
