import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../models/song.dart';
import 'audio_formats.dart';
import 'id3_parser.dart';
import 'id3_writer.dart';

class SongEditor {
  SongEditor._();

  static bool get canEdit => true;

  static bool supportsTags(Song song) {
    return p.extension(song.id).toLowerCase() == '.mp3';
  }

  static Future<bool> saveTags({
    required Song song,
    required String title,
    required String artist,
    required String album,
    required String lyrics,
    Uint8List? cover,
    String? coverMime,
    bool keepCover = true,
  }) async {
    if (!supportsTags(song)) return false;

    final file = File(song.id);
    if (!await file.exists()) return false;

    try {
      final bytes = await file.readAsBytes();
      final existing = Id3Parser.parse(bytes);

      final picture = cover ?? (keepCover ? existing.picture : null);
      final mime = cover != null ? coverMime : existing.pictureMime;

      final updated = Id3Writer.apply(
        bytes,
        AudioTags(
          title: title,
          artist: artist,
          album: album,
          lyrics: lyrics,
          picture: picture,
          pictureMime: mime,
        ),
      );

      final backup = File('${song.id}.bak');
      await file.copy(backup.path);
      await file.writeAsBytes(updated, flush: true);
      await backup.delete();

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> renameFile(Song song, String newName) async {
    final file = File(song.id);
    if (!await file.exists()) return null;

    final clean = _safeName(newName);
    if (clean.isEmpty) return null;

    final extension = p.extension(song.id);
    if (!AudioFormats.supports(extension)) return null;

    final target = p.join(p.dirname(song.id), '$clean$extension');
    if (target == song.id) return song.id;

    try {
      if (await File(target).exists()) return null;
      final moved = await file.rename(target);
      return moved.path;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> deleteFile(Song song) async {
    try {
      final file = File(song.id);
      if (!await file.exists()) return false;
      await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _safeName(String value) {
    const forbidden = '\\/:*?"<>|';
    final buffer = StringBuffer();

    for (final char in value.trim().split('')) {
      buffer.write(forbidden.contains(char) ? ' ' : char);
    }

    return buffer.toString().trim();
  }
}
