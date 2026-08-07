class Playlist {
  final String id;
  final String title;
  final String cover;
  final List<String> songs;

  Playlist({
    required this.id,
    required this.title,
    required this.songs,
    this.cover = '',
  });

  int get songCount => songs.length;

  bool get hasCover => cover.isNotEmpty;
}
