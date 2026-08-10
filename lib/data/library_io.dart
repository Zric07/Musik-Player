import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as p;

import '../models/song.dart';
import 'app_paths.dart';
import 'id3_reader.dart';

class MusicLibrary {
  MusicLibrary._();

  static const int _maxDepth = 6;

  static bool get canImport => false;

  static String get importLabel => '';

  static Future<int> import() async => 0;

  static Future<void> setSource(AudioPlayer player, Song song) async {
    await player.setFilePath(song.id, tag: _tag(song));
  }

  static MediaItem _tag(Song song) {
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album.isEmpty ? null : song.album,
      duration: song.hasDuration ? song.duration : null,
      artUri: song.hasCover ? Uri.file(song.cover) : null,
    );
  }

  static Future<List<Song>> load() async {
    final artwork = await AppPaths.artwork();
    final songs = <Song>[];
    final seen = <String>{};

    for (final root in AppPaths.musicRoots()) {
      await _walk(Directory(root), 0, songs, seen, artwork);
    }

    songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return songs;
  }

  static Future<void> _walk(
    Directory directory,
    int depth,
    List<Song> songs,
    Set<String> seen,
    Directory artwork,
  ) async {
    if (depth > _maxDepth) return;
    if (!await directory.exists()) return;

    final List<FileSystemEntity> entries;
    try {
      entries = await directory.list(followLinks: false).toList();
    } catch (_) {
      return;
    }

    for (final entry in entries) {
      final name = p.basename(entry.path);
      if (name.startsWith('.')) continue;

      if (entry is Directory) {
        await _walk(entry, depth + 1, songs, seen, artwork);
        continue;
      }

      if (entry is! File) continue;
      if (p.extension(entry.path).toLowerCase() != '.mp3') continue;
      if (!seen.add(entry.path)) continue;

      songs.add(await _readSong(entry, artwork));
    }
  }

  static Future<Song> _readSong(File file, Directory artwork) async {
    final fallback = p.basenameWithoutExtension(file.path);
    final tags = await Id3Reader.read(file);

    var cover = '';
    final picture = tags.picture;
    if (picture != null && picture.isNotEmpty) {
      cover = await _storeArtwork(file.path, picture, tags.pictureMime, artwork);
    }

    return Song(
      id: file.path,
      title: tags.title ?? fallback,
      artist: tags.artist ?? 'Unbekannt',
      album: tags.album ?? '',
      cover: cover,
      duration: await Id3Reader.duration(file) ?? Duration.zero,
      lyrics: tags.lyrics ?? '',
      timedLyrics: tags.timedLyrics,
    );
  }

  static Future<String> _storeArtwork(
    String songPath,
    List<int> bytes,
    String? mime,
    Directory artwork,
  ) async {
    final extension = (mime ?? '').contains('png') ? '.png' : '.jpg';
    final target = File(
      p.join(artwork.path, '${_hash(songPath)}$extension'),
    );

    try {
      if (!await target.exists() || await target.length() != bytes.length) {
        await target.writeAsBytes(bytes, flush: true);
      }
      return target.path;
    } catch (_) {
      return '';
    }
  }

  static String _hash(String value) {
    var hash = 5381;
    for (final unit in value.codeUnits) {
      hash = ((hash << 5) + hash + unit) & 0x7FFFFFFF;
    }
    return hash.toRadixString(16);
  }
}
