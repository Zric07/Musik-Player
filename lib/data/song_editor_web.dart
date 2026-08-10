import 'dart:typed_data';

import '../models/song.dart';

class SongEditor {
  SongEditor._();

  static bool get canEdit => false;

  static bool supportsTags(Song song) => false;

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
    return false;
  }

  static Future<String?> renameFile(Song song, String newName) async => null;

  static Future<bool> deleteFile(Song song) async => false;
}
