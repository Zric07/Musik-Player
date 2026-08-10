import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

class PickedImage {
  final Uint8List bytes;
  final String mime;

  const PickedImage(this.bytes, this.mime);
}

class ImagePickerService {
  ImagePickerService._();

  static Future<PickedImage?> pick() async {
    const group = XTypeGroup(
      label: 'Bilder',
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'avif', 'gif', 'bmp'],
      mimeTypes: ['image/*'],
    );

    final file = await openFile(acceptedTypeGroups: const [group]);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;

    return PickedImage(bytes, _mimeFor(file.name));
  }

  static String _mimeFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    return 'image/jpeg';
  }
}
