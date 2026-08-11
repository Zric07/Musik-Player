class LibraryPermission {
  LibraryPermission._();

  static Future<bool> ensure() async => true;

  static Future<void> ensureNotifications() async {}

  static Future<void> ensureMicrophone() async {}

  static Future<bool> isPermanentlyDenied() async => false;

  static Future<void> openSettings() async {}
}
