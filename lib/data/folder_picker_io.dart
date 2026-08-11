import 'package:file_selector/file_selector.dart';

import 'app_paths.dart';

class FolderPicker {
  FolderPicker._();

  static bool get supported => true;

  static Future<String?> pick() => getDirectoryPath();

  static List<String> defaults() => AppPaths.defaultRoots();
}
