enum RepeatMode { off, all, one }

enum SongOrder { title, artist, album, duration }

extension RepeatModeLabel on RepeatMode {
  RepeatMode get next => switch (this) {
    RepeatMode.off => RepeatMode.all,
    RepeatMode.all => RepeatMode.one,
    RepeatMode.one => RepeatMode.off,
  };

  String get label => switch (this) {
    RepeatMode.off => 'Keine Wiederholung',
    RepeatMode.all => 'Warteschlange wiederholen',
    RepeatMode.one => 'Titel wiederholen',
  };
}

extension SongOrderLabel on SongOrder {
  String get label => switch (this) {
    SongOrder.title => 'Titel',
    SongOrder.artist => 'Interpret',
    SongOrder.album => 'Album',
    SongOrder.duration => 'Länge',
  };
}
