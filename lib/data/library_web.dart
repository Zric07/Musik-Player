import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import 'id3_parser.dart';
import 'mp3_duration.dart';
import 'cover_cache.dart';

class MusicLibrary {
  MusicLibrary._();

  static final List<Song> _songs = [];

  static bool get canImport => true;

  static String get importLabel => 'Musik auswählen';

  static Future<List<Song>> load() async => List.of(_songs);

  static Future<int> import() async {
    const group = XTypeGroup(
      label: 'Musik',
      extensions: ['mp3', 'wav'],
      mimeTypes: ['audio/mpeg'],
    );

    final files = await openFiles(acceptedTypeGroups: const [group]);
    if (files.isEmpty) return 0;

    var added = 0;
    for (final file in files) {
      final song = await _toSong(file);
      if (song == null) continue;
      if (_songs.any((existing) => existing.id == song.id)) continue;

      _songs.add(song);
      added++;
    }

    _songs.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return added;
  }

  static Future<void> setSource(AudioPlayer player, Song song) async {
    await player.setUrl(song.id);
  }

  static Future<Song?> _toSong(XFile file) async {
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      return null;
    }

    if (bytes.isEmpty) return null;

    final tags = Id3Parser.parse(bytes);
    final fallback = _withoutExtension(file.name);

    var cover = '';
    final picture = tags.picture;
    if (picture != null && picture.isNotEmpty) {
      cover = CoverCache.store('song-${file.path.hashCode}', picture);
    }

    return Song(
      id: file.path,
      title: tags.title ?? fallback,
      artist: tags.artist ?? 'Unbekannt',
      album: tags.album ?? '',
      cover: cover,
      duration: Mp3Duration.estimate(bytes, bytes.length) ?? Duration.zero,
      lyrics: tags.lyrics ?? '',
      timedLyrics: tags.timedLyrics,
    );
  }

  static String _withoutExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}
