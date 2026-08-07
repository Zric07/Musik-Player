import 'dart:typed_data';

import 'package:sqflite_common/sqlite_api.dart';

import '../models/playlist.dart';
import 'cover_cache.dart';
import 'database.dart';

class PlaylistStore {
  PlaylistStore._();

  static Future<void> create(String title) async {
    final db = await AppDatabase.instance();
    await db.insert('playlists', {'id': _newId(), 'title': title});
  }

  static Future<void> rename(String id, String title) async {
    final db = await AppDatabase.instance();
    final changed = await db.update(
      'playlists',
      {'title': title},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (changed == 0) throw Exception('Playlist nicht gefunden');
  }

  static Future<void> delete(String id) async {
    final db = await AppDatabase.instance();

    await db.delete(
      'playlist_songs',
      where: 'playlist_id = ?',
      whereArgs: [id],
    );

    final changed = await db.delete(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
    );

    CoverCache.forget(_owner(id));
    if (changed == 0) throw Exception('Playlist nicht gefunden');
  }

  static Future<List<Playlist>> all() async {
    final db = await AppDatabase.instance();
    final rows = await db.query('playlists', orderBy: 'title COLLATE NOCASE');

    final playlists = <Playlist>[];
    for (final row in rows) {
      playlists.add(await _build(db, row));
    }
    return playlists;
  }

  static Future<Playlist> one(String id) async {
    final db = await AppDatabase.instance();
    final rows = await db.query(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) throw Exception('Playlist nicht gefunden');
    return _build(db, rows.first);
  }

  static Future<void> addSong(String playlistId, String songPath) async {
    final db = await AppDatabase.instance();

    final result = await db.rawQuery(
      'SELECT COALESCE(MAX(position), -1) + 1 AS next '
      'FROM playlist_songs WHERE playlist_id = ?',
      [playlistId],
    );

    await db.insert(
      'playlist_songs',
      {
        'playlist_id': playlistId,
        'song_path': songPath,
        'position': (result.first['next'] as int?) ?? 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> removeSong(String playlistId, String songPath) async {
    final db = await AppDatabase.instance();
    await db.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_path = ?',
      whereArgs: [playlistId, songPath],
    );
  }

  static Future<void> saveCover(String id, Uint8List bytes) async {
    final db = await AppDatabase.instance();
    await db.update(
      'playlists',
      {'cover': bytes},
      where: 'id = ?',
      whereArgs: [id],
    );
    CoverCache.forget(_owner(id));
  }

  static Future<void> deleteCover(String id) async {
    final db = await AppDatabase.instance();
    await db.update(
      'playlists',
      {'cover': null},
      where: 'id = ?',
      whereArgs: [id],
    );
    CoverCache.forget(_owner(id));
  }

  static Future<Playlist> _build(Database db, Map<String, Object?> row) async {
    final id = row['id'] as String;

    final songRows = await db.query(
      'playlist_songs',
      columns: ['song_path'],
      where: 'playlist_id = ?',
      whereArgs: [id],
      orderBy: 'position',
    );

    var cover = '';
    final blob = row['cover'];
    if (blob is Uint8List && blob.isNotEmpty) {
      cover = CoverCache.store(_owner(id), blob);
    } else if (blob is List<int> && blob.isNotEmpty) {
      cover = CoverCache.store(_owner(id), Uint8List.fromList(blob));
    }

    return Playlist(
      id: id,
      title: row['title'] as String,
      cover: cover,
      songs: songRows.map((e) => e['song_path'] as String).toList(),
    );
  }

  static String _owner(String id) => 'playlist-$id';

  static String _newId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final salt = identityHashCode(Object()) & 0xFFFFFF;
    return '${now.toRadixString(16)}-${salt.toRadixString(16)}';
  }
}
