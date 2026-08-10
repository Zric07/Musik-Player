import 'dart:typed_data';

class WavDuration {
  WavDuration._();

  static Duration? estimate(Uint8List head, int fileLength) {
    if (head.length < 44) return null;
    if (_tag(head, 0) != 'RIFF' || _tag(head, 8) != 'WAVE') return null;

    var offset = 12;
    var byteRate = 0;

    while (offset + 8 <= head.length) {
      final id = _tag(head, offset);
      final size = _leUint32(head, offset + 4);
      if (size < 0) return null;

      if (id == 'fmt ' && offset + 16 <= head.length) {
        byteRate = _leUint32(head, offset + 16);
      }

      if (id == 'data') {
        if (byteRate <= 0) return null;

        final available = fileLength - (offset + 8);
        final bytes = size > 0 && size <= available ? size : available;
        if (bytes <= 0) return null;

        final seconds = bytes / byteRate;
        return Duration(milliseconds: (seconds * 1000).round());
      }

      offset += 8 + size + (size.isOdd ? 1 : 0);
    }

    return null;
  }

  static String _tag(Uint8List data, int offset) {
    if (offset + 4 > data.length) return '';
    return String.fromCharCodes(data.sublist(offset, offset + 4));
  }

  static int _leUint32(Uint8List data, int offset) {
    if (offset + 4 > data.length) return -1;
    return data[offset] |
        data[offset + 1] << 8 |
        data[offset + 2] << 16 |
        data[offset + 3] << 24;
  }
}
