import '../models/song.dart';
import '../models/stats.dart';
import 'database.dart';

class PlayHistory {
  PlayHistory._();

  static const Duration minimum = Duration(seconds: 5);

  static Future<void> record({
    required Song song,
    required Duration listened,
    required bool finished,
  }) async {
    if (listened < minimum) return;

    final db = await AppDatabase.instance();
    await db.insert('plays', {
      'song_path': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'played_at': DateTime.now().millisecondsSinceEpoch,
      'seconds': listened.inSeconds,
      'finished': finished ? 1 : 0,
    });
  }

  static Future<ListeningStats> load({int days = 7}) async {
    final db = await AppDatabase.instance();

    final totals = await db.rawQuery('''
      SELECT
        COALESCE(SUM(seconds), 0)        AS seconds,
        COUNT(*)                         AS plays,
        COUNT(DISTINCT song_path)        AS songs,
        COUNT(DISTINCT artist)           AS artists,
        COALESCE(SUM(1 - finished), 0)   AS skipped
      FROM plays
    ''');

    final row = totals.first;
    final plays = (row['plays'] as int?) ?? 0;

    if (plays == 0) return ListeningStats.empty;

    final songRows = await db.rawQuery('''
      SELECT title, artist, COUNT(*) AS plays, SUM(seconds) AS seconds
      FROM plays
      GROUP BY song_path
      ORDER BY seconds DESC
      LIMIT 5
    ''');

    final artistRows = await db.rawQuery('''
      SELECT artist, COUNT(*) AS plays, SUM(seconds) AS seconds,
             COUNT(DISTINCT song_path) AS songs
      FROM plays
      GROUP BY artist
      ORDER BY seconds DESC
      LIMIT 5
    ''');

    return ListeningStats(
      total: Duration(seconds: (row['seconds'] as int?) ?? 0),
      plays: plays,
      distinctSongs: (row['songs'] as int?) ?? 0,
      distinctArtists: (row['artists'] as int?) ?? 0,
      skipped: (row['skipped'] as int?) ?? 0,
      topSongs: songRows
          .map(
            (e) => RankedEntry(
              label: e['title'] as String,
              detail: e['artist'] as String,
              plays: (e['plays'] as int?) ?? 0,
              listened: Duration(seconds: (e['seconds'] as int?) ?? 0),
            ),
          )
          .toList(),
      topArtists: artistRows
          .map(
            (e) => RankedEntry(
              label: e['artist'] as String,
              detail: _songLabel((e['songs'] as int?) ?? 0),
              plays: (e['plays'] as int?) ?? 0,
              listened: Duration(seconds: (e['seconds'] as int?) ?? 0),
            ),
          )
          .toList(),
      lastDays: await _days(days),
    );
  }

  static Future<List<DayBar>> _days(int days) async {
    final db = await AppDatabase.instance();

    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    final rows = await db.rawQuery(
      'SELECT played_at, seconds FROM plays WHERE played_at >= ?',
      [first.millisecondsSinceEpoch],
    );

    final buckets = <int, int>{};
    for (final row in rows) {
      final at = DateTime.fromMillisecondsSinceEpoch(
        (row['played_at'] as int?) ?? 0,
      );
      final day = DateTime(at.year, at.month, at.day);
      final index = day.difference(first).inDays;
      if (index < 0 || index >= days) continue;

      buckets[index] = (buckets[index] ?? 0) + ((row['seconds'] as int?) ?? 0);
    }

    return List.generate(days, (i) {
      return DayBar(
        day: first.add(Duration(days: i)),
        listened: Duration(seconds: buckets[i] ?? 0),
      );
    });
  }

  static Future<void> clear() async {
    final db = await AppDatabase.instance();
    await db.delete('plays');
  }

  static String _songLabel(int count) =>
      count == 1 ? '1 Titel' : '$count Titel';
}
