class FolderPicker {
  FolderPicker._();

  static bool get supported => false;

  static Future<String?> pick() async => null;

  static List<String> defaults() => const [];
}
