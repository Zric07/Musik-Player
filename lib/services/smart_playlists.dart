import '../data/favorite_store.dart';
import '../data/play_history.dart';
import '../models/collection.dart';
import '../models/song.dart';

enum SmartKind { recent, mostPlayed, neglected, neverHeard, favorites }

extension SmartKindLabel on SmartKind {
  String get title => switch (this) {
    SmartKind.recent => 'Zuletzt gehört',
    SmartKind.mostPlayed => 'Meistgehört',
    SmartKind.neglected => 'Lange nicht gehört',
    SmartKind.neverHeard => 'Noch nie gehört',
    SmartKind.favorites => 'Favoriten',
  };

  String get hint => switch (this) {
    SmartKind.recent => 'Deine letzten Titel',
    SmartKind.mostPlayed => 'Was du am häufigsten hörst',
    SmartKind.neglected => 'Seit über einem Monat still',
    SmartKind.neverHeard => 'Wartet noch auf dich',
    SmartKind.favorites => 'Von dir markiert',
  };
}

class SmartPlaylists {
  SmartPlaylists._();

  static Future<Collection> build(SmartKind kind, List<Song> library) async {
    final songs = await _songsFor(kind, library);

    return Collection(
      name: kind.title,
      subtitle: kind.hint,
      songs: songs,
    );
  }

  static Future<List<Song>> _songsFor(
    SmartKind kind,
    List<Song> library,
  ) async {
    if (library.isEmpty) return const [];

    final byId = {for (final song in library) song.id: song};

    switch (kind) {
      case SmartKind.recent:
        return _pick(await PlayHistory.recentPaths(), byId);

      case SmartKind.mostPlayed:
        return _pick(await PlayHistory.mostPlayedPaths(), byId);

      case SmartKind.neglected:
        return _pick(await PlayHistory.neglectedPaths(), byId);

      case SmartKind.neverHeard:
        final heard = await PlayHistory.heardPaths();
        return library.where((song) => !heard.contains(song.id)).toList();

      case SmartKind.favorites:
        await FavoriteStore.load();
        return library
            .where((song) => FavoriteStore.contains(song.id))
            .toList();
    }
  }

  static List<Song> _pick(List<String> paths, Map<String, Song> byId) {
    return paths.map((path) => byId[path]).whereType<Song>().toList();
  }
}
