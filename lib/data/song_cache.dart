import 'package:sqflite_common/sqlite_api.dart';

import '../models/song.dart';
import 'database.dart';
import 'id3_parser.dart';

class CachedSong {
  final Song song;
  final int modified;
  final int size;

  const CachedSong(this.song, this.modified, this.size);
}

class SongCache {
  SongCache._();

  static Future<Map<String, CachedSong>> load() async {
    try {
      final db = await AppDatabase.instance();
      final rows = await db.query('song_cache');

      return {
        for (final row in rows) row['path'] as String: _toCached(row),
      };
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(List<CachedSong> entries) async {
    if (entries.isEmpty) return;

    try {
      final db = await AppDatabase.instance();
      final batch = db.batch();

      for (final entry in entries) {
        batch.insert(
          'song_cache',
          _toRow(entry),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    } catch (_) {}
  }

  static Future<void> forget(Iterable<String> paths) async {
    if (paths.isEmpty) return;

    try {
      final db = await AppDatabase.instance();
      final batch = db.batch();

      for (final path in paths) {
        batch.delete('song_cache', where: 'path = ?', whereArgs: [path]);
      }

      await batch.commit(noResult: true);
    } catch (_) {}
  }

  static CachedSong _toCached(Map<String, Object?> row) {
    return CachedSong(
      Song(
        id: row['path'] as String,
        title: row['title'] as String,
        artist: row['artist'] as String,
        album: row['album'] as String,
        cover: row['cover'] as String,
        duration: Duration(milliseconds: row['duration'] as int),
        lyrics: row['lyrics'] as String,
        timedLyrics: decodeTimed(row['timed'] as String),
      ),
      row['modified'] as int,
      row['size'] as int,
    );
  }

  static Map<String, Object?> _toRow(CachedSong entry) {
    final song = entry.song;

    return {
      'path': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'cover': song.cover,
      'duration': song.duration.inMilliseconds,
      'lyrics': song.lyrics,
      'timed': encodeTimed(song.timedLyrics),
      'modified': entry.modified,
      'size': entry.size,
    };
  }

  static const String _field = '\u0001';
  static const String _record = '\u0002';

  static String encodeTimed(List<LyricLine> lines) {
    if (lines.isEmpty) return '';

    return lines
        .map((line) => '${line.time.inMilliseconds}$_field${line.text}')
        .join(_record);
  }

  static List<LyricLine> decodeTimed(String value) {
    if (value.isEmpty) return const [];

    final lines = <LyricLine>[];

    for (final entry in value.split(_record)) {
      final parts = entry.split(_field);
      if (parts.length != 2) continue;

      final ms = int.tryParse(parts[0]);
      if (ms == null) continue;

      lines.add(
        LyricLine(time: Duration(milliseconds: ms), text: parts[1]),
      );
    }

    return lines;
  }
}
