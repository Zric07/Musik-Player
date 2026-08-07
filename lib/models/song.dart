import '../data/id3_parser.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String cover;
  final String lyrics;
  final List<LyricLine> timedLyrics;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album = '',
    this.cover = '',
    this.lyrics = '',
    this.timedLyrics = const [],
  });

  bool get hasCover => cover.isNotEmpty;

  bool get hasLyrics => lyrics.isNotEmpty || timedLyrics.isNotEmpty;

  bool get hasTimedLyrics => timedLyrics.isNotEmpty;
}
