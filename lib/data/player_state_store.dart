import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';

import '../models/playback.dart';
import 'database.dart';

class StoredState {
  final List<String> songIds;
  final int index;
  final Duration elapsed;
  final bool shuffle;
  final RepeatMode repeat;
  final double volume;

  const StoredState({
    required this.songIds,
    required this.index,
    required this.elapsed,
    required this.shuffle,
    required this.repeat,
    required this.volume,
  });
}

class PlayerStateStore {
  PlayerStateStore._();

  static Future<void> save({
    required List<String> songIds,
    required int index,
    required Duration elapsed,
    required bool shuffle,
    required RepeatMode repeat,
    required double volume,
  }) async {
    final db = await AppDatabase.instance();

    await db.insert('player_state', {
      'id': 1,
      'songs': jsonEncode(songIds),
      'position': index,
      'elapsed': elapsed.inMilliseconds,
      'shuffle': shuffle ? 1 : 0,
      'repeat': repeat.index,
      'volume': volume,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<StoredState?> load() async {
    final db = await AppDatabase.instance();

    final rows = await db.query('player_state', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;

    final row = rows.first;

    final raw = jsonDecode((row['songs'] as String?) ?? '[]');
    if (raw is! List || raw.isEmpty) return null;

    final repeatIndex = (row['repeat'] as int?) ?? 0;

    return StoredState(
      songIds: raw.map((e) => e.toString()).toList(),
      index: (row['position'] as int?) ?? 0,
      elapsed: Duration(milliseconds: (row['elapsed'] as int?) ?? 0),
      shuffle: ((row['shuffle'] as int?) ?? 0) == 1,
      repeat: repeatIndex < RepeatMode.values.length
          ? RepeatMode.values[repeatIndex]
          : RepeatMode.off,
      volume: ((row['volume'] as num?) ?? 1).toDouble(),
    );
  }

  static Future<void> clear() async {
    final db = await AppDatabase.instance();
    await db.delete('player_state');
  }
}
