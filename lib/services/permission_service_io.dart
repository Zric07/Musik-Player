import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class LibraryPermission {
  LibraryPermission._();

  static Future<bool> ensure() async {
    if (!Platform.isAndroid) return true;

    if (await Permission.audio.isGranted) return true;
    if (await Permission.storage.isGranted) return true;

    final audio = await Permission.audio.request();
    if (audio.isGranted) return true;

    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  static Future<bool> isPermanentlyDenied() async {
    if (!Platform.isAndroid) return false;
    return await Permission.audio.isPermanentlyDenied &&
        await Permission.storage.isPermanentlyDenied;
  }

  static Future<void> openSettings() => openAppSettings();
}
