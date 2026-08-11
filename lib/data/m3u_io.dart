import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;

import '../models/song.dart';
import 'audio_formats.dart';

class M3u {
  M3u._();

  static bool get supported => true;

  static Future<bool> export(String title, List<Song> songs) async {
    if (songs.isEmpty) return false;

    final location = await getSaveLocation(
      suggestedName: '${_safeName(title)}.m3u8',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Playlist', extensions: ['m3u8', 'm3u']),
      ],
    );

    if (location == null) return false;

    final buffer = StringBuffer('#EXTM3U\n');

    for (final song in songs) {
      final seconds = song.duration.inSeconds;
      buffer
        ..writeln('#EXTINF:$seconds,${song.artist} - ${song.title}')
        ..writeln(song.id);
    }

    try {
      await File(location.path).writeAsString(
        buffer.toString(),
        encoding: utf8,
        flush: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<String>> importPaths() async {
    const group = XTypeGroup(
      label: 'Playlist',
      extensions: ['m3u8', 'm3u'],
    );

    final file = await openFile(acceptedTypeGroups: const [group]);
    if (file == null) return const [];

    final String content;
    try {
      content = await File(file.path).readAsString();
    } catch (_) {
      return const [];
    }

    final base = p.dirname(file.path);
    final paths = <String>[];

    for (final raw in const LineSplitter().convert(content)) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      if (!AudioFormats.supports(p.extension(line))) continue;

      final full = p.isAbsolute(line) ? line : p.normalize(p.join(base, line));
      if (!paths.contains(full)) paths.add(full);
    }

    return paths;
  }

  static String _safeName(String value) {
    const forbidden = '\\/:*?"<>|';
    final buffer = StringBuffer();

    for (final char in value.trim().split('')) {
      buffer.write(forbidden.contains(char) ? ' ' : char);
    }

    final clean = buffer.toString().trim();
    return clean.isEmpty ? 'playlist' : clean;
  }
}
