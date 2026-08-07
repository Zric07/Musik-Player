class LibraryPermission {
  LibraryPermission._();

  static Future<bool> ensure() async => true;

  static Future<bool> isPermanentlyDenied() async => false;

  static Future<void> openSettings() async {}
}
