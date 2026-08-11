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
        version: 6,
        onCreate: _create,
        onUpgrade: _upgrade,
      ),
    );

    _database = database;
    return database;
  }

  static Future<void> _upgrade(Database db, int from, int to) async {
    if (from < 2) await _createPlays(db);
    if (from < 3) await _createState(db);
    if (from < 4) await _createFavorites(db);
    if (from < 5) await _createCache(db);
    if (from < 6) await _createSettings(db);
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
    await _createState(db);
    await _createFavorites(db);
    await _createCache(db);
    await _createSettings(db);
  }

  static Future<void> _createSettings(Database db) async {
    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createCache(Database db) async {
    await db.execute('''
      CREATE TABLE song_cache (
        path     TEXT PRIMARY KEY,
        title    TEXT NOT NULL,
        artist   TEXT NOT NULL,
        album    TEXT NOT NULL,
        cover    TEXT NOT NULL,
        duration INTEGER NOT NULL,
        lyrics   TEXT NOT NULL,
        timed    TEXT NOT NULL,
        modified INTEGER NOT NULL,
        size     INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _createFavorites(Database db) async {
    await db.execute('''
      CREATE TABLE favorites (
        song_path TEXT PRIMARY KEY,
        added_at  INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _createState(Database db) async {
    await db.execute('''
      CREATE TABLE player_state (
        id       INTEGER PRIMARY KEY CHECK (id = 1),
        songs    TEXT    NOT NULL,
        position INTEGER NOT NULL,
        elapsed  INTEGER NOT NULL,
        shuffle  INTEGER NOT NULL,
        repeat   INTEGER NOT NULL,
        volume   REAL    NOT NULL
      )
    ''');
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
