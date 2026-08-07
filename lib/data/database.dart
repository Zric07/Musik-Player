import 'package:sqflite_common/sqlite_api.dart';

import 'db_factory.dart';

class AppDatabase {
  AppDatabase._();

  static Database? _database;

  static Future<Database> instance() async {
    final cached = _database;
    if (cached != null) return cached;

    final factory = await databaseBackend();
    final path = await databaseLocation();

    final database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _create,
        onUpgrade: _upgrade,
      ),
    );

    _database = database;
    return database;
  }

  static Future<void> _upgrade(Database db, int from, int to) async {
    if (from < 2) await _createPlays(db);
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE playlists (
        id    TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        cover BLOB
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_songs (
        playlist_id TEXT NOT NULL,
        song_path   TEXT NOT NULL,
        position    INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, song_path)
      )
    ''');

    await _createPlays(db);
  }

  static Future<void> _createPlays(Database db) async {
    await db.execute('''
      CREATE TABLE plays (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        song_path  TEXT NOT NULL,
        title      TEXT NOT NULL,
        artist     TEXT NOT NULL,
        album      TEXT NOT NULL,
        played_at  INTEGER NOT NULL,
        seconds    INTEGER NOT NULL,
        finished   INTEGER NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX plays_played_at ON plays (played_at)');
    await db.execute('CREATE INDEX plays_song ON plays (song_path)');
  }
}
