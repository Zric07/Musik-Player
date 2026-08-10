import 'song.dart';

class Collection {
  final String name;
  final String subtitle;
  final List<Song> songs;

  const Collection({
    required this.name,
    required this.subtitle,
    required this.songs,
  });

  Duration get total => songs.fold(
    Duration.zero,
    (sum, song) => sum + song.duration,
  );

  String get coverKey => songs.isEmpty ? name : songs.first.id;
}

class CollectionBuilder {
  CollectionBuilder._();

  static List<Collection> albums(List<Song> songs) {
    final groups = <String, List<Song>>{};

    for (final song in songs) {
      final key = song.album.trim().isEmpty ? 'Ohne Album' : song.album.trim();
      groups.putIfAbsent(key, () => []).add(song);
    }

    return _sorted(groups, (entry) {
      final artists = entry.value.map((s) => s.artist).toSet();
      return artists.length == 1 ? artists.first : 'Verschiedene Interpreten';
    });
  }

  static List<Collection> artists(List<Song> songs) {
    final groups = <String, List<Song>>{};

    for (final song in songs) {
      final key = song.artist.trim().isEmpty ? 'Unbekannt' : song.artist.trim();
      groups.putIfAbsent(key, () => []).add(song);
    }

    return _sorted(groups, (entry) {
      final albums = entry.value
          .map((s) => s.album)
          .where((a) => a.isNotEmpty)
          .toSet();
      return albums.length == 1 ? albums.first : _albumLabel(albums.length);
    });
  }

  static List<Collection> _sorted(
    Map<String, List<Song>> groups,
    String Function(MapEntry<String, List<Song>>) subtitle,
  ) {
    final result = groups.entries
        .map(
          (entry) => Collection(
            name: entry.key,
            subtitle: subtitle(entry),
            songs: entry.value,
          ),
        )
        .toList();

    result.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return result;
  }

  static String _albumLabel(int count) {
    if (count == 0) return 'Ohne Album';
    return count == 1 ? '1 Album' : '$count Alben';
  }
}
