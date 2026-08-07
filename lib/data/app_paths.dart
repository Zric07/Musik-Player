import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppPaths {
  AppPaths._();

  static Directory? _root;

  static Future<Directory> root() async {
    final cached = _root;
    if (cached != null) return cached;

    final base = await getApplicationSupportDirectory();
    final directory = Directory(p.join(base.path, 'MusikApp'));
    await directory.create(recursive: true);

    _root = directory;
    return directory;
  }

  static Future<Directory> artwork() => _sub('artwork');

  static Future<String> databaseFile() async {
    final directory = await root();
    return p.join(directory.path, 'musik.db');
  }

  static Future<Directory> _sub(String name) async {
    final directory = Directory(p.join((await root()).path, name));
    await directory.create(recursive: true);
    return directory;
  }

  static List<String> musicRoots() {
    if (Platform.isAndroid) {
      return const [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/Podcasts',
      ];
    }

    final home =
        Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        '';

    if (home.isEmpty) return const [];

    return [
      p.join(home, 'Music'),
      p.join(home, 'Downloads'),
      p.join(home, 'Documents'),
      p.join(home, 'Desktop'),
      p.join(home, 'Musik'),
      p.join(home, 'Dokumente'),
    ];
  }
}
