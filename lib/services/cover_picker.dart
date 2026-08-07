import 'package:file_selector/file_selector.dart';

import 'playlist_service.dart';

class CoverPicker {
  CoverPicker._();

  static Future<bool> pickAndUpload(String playlistId) async {
    const group = XTypeGroup(
      label: 'Bilder',
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'avif', 'gif', 'bmp'],
      mimeTypes: ['image/*'],
    );

    final file = await openFile(acceptedTypeGroups: const [group]);
    if (file == null) return false;

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return false;

    await PlaylistService().setCover(playlistId, bytes);
    return true;
  }
}
