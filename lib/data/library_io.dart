import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as p;

import '../models/song.dart';
import 'app_paths.dart';
import 'audio_formats.dart';
import 'id3_reader.dart';
import 'song_cache.dart';

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

  static Future<List<Song>> load({void Function(int)? onProgress}) async {
    final artwork = await AppPaths.artwork();
    final files = <File>[];
    final seen = <String>{};

    for (final root in AppPaths.musicRoots()) {
      await _walk(Directory(root), 0, files, seen);
    }

    final cache = await SongCache.load();
    final songs = <Song>[];
    final fresh = <CachedSong>[];

    for (final file in files) {
      final stat = await _statOf(file);
      final cached = cache[file.path];

      if (cached != null &&
          stat != null &&
          cached.modified == stat.modified.millisecondsSinceEpoch &&
          cached.size == stat.size) {
        songs.add(cached.song);
        onProgress?.call(songs.length);
        continue;
      }

      final song = await _readSong(file, artwork);
      songs.add(song);
      onProgress?.call(songs.length);

      if (stat != null) {
        fresh.add(
          CachedSong(song, stat.modified.millisecondsSinceEpoch, stat.size),
        );
      }
    }

    final gone = cache.keys.where((path) => !seen.contains(path)).toList();

    await SongCache.save(fresh);
    await SongCache.forget(gone);

    songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return songs;
  }

  static Future<FileStat?> _statOf(File file) async {
    try {
      return await file.stat();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _walk(
    Directory directory,
    int depth,
    List<File> files,
    Set<String> seen,
  ) async {
    if (depth > _maxDepth) return;
    if (AppPaths.isExcluded(directory.path)) return;
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
        await _walk(entry, depth + 1, files, seen);
        continue;
      }

      if (entry is! File) continue;
      if (!AudioFormats.supports(p.extension(entry.path))) continue;
      if (!seen.add(entry.path)) continue;

      files.add(entry);
    }
  }

  static Future<Song> _readSong(File file, Directory artwork) async {
    final fallback = p.basenameWithoutExtension(file.path);
    final extension = p.extension(file.path).toLowerCase();
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
      duration: await Id3Reader.duration(file, extension) ?? Duration.zero,
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
