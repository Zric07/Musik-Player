import 'dart:async';

import 'database.dart';

class FavoriteStore {
  FavoriteStore._();

  static final Set<String> _cache = {};
  static bool _loaded = false;

  static final _changes = StreamController<void>.broadcast();

  static Stream<void> get changes => _changes.stream;

  static Future<Set<String>> load() async {
    if (_loaded) return _cache;

    final db = await AppDatabase.instance();
    final rows = await db.query('favorites', columns: ['song_path']);

    _cache
      ..clear()
      ..addAll(rows.map((row) => row['song_path'] as String));
    _loaded = true;

    return _cache;
  }

  static bool contains(String songPath) => _cache.contains(songPath);

  static Future<bool> toggle(String songPath) async {
    await load();

    final db = await AppDatabase.instance();
    final isFavorite = _cache.contains(songPath);

    if (isFavorite) {
      _cache.remove(songPath);
      await db.delete(
        'favorites',
        where: 'song_path = ?',
        whereArgs: [songPath],
      );
    } else {
      _cache.add(songPath);
      await db.insert('favorites', {
        'song_path': songPath,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });
    }

    _changes.add(null);
    return !isFavorite;
  }
}
