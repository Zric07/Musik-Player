import '../models/song.dart';

class M3u {
  M3u._();

  static bool get supported => false;

  static Future<bool> export(String title, List<Song> songs) async => false;

  static Future<List<String>> importPaths() async => const [];
}
