import 'dart:typed_data';

class Mp3Duration {
  Mp3Duration._();

  static const List<int> _bitratesV1L3 = [
    0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0,
  ];

  static const List<int> _bitratesV2L3 = [
    0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0,
  ];

  static const List<int> _ratesV1 = [44100, 48000, 32000, 0];
  static const List<int> _ratesV2 = [22050, 24000, 16000, 0];
  static const List<int> _ratesV25 = [11025, 12000, 8000, 0];

  static Duration? estimate(Uint8List head, int fileLength) {
    final start = _skipTag(head);
    final frame = _findFrame(head, start);
    if (frame == null) return null;

    final samples = frame.version == 1 ? 1152 : 576;

    final xing = _xingFrames(head, frame);
    if (xing != null && xing > 0) {
      final seconds = xing * samples / frame.sampleRate;
      return Duration(milliseconds: (seconds * 1000).round());
    }

    if (frame.bitrate <= 0) return null;

    final audioBytes = fileLength - start;
    if (audioBytes <= 0) return null;

    final seconds = audioBytes * 8 / (frame.bitrate * 1000);
    return Duration(milliseconds: (seconds * 1000).round());
  }

  static int _skipTag(Uint8List data) {
    if (data.length < 10) return 0;
    if (data[0] != 0x49 || data[1] != 0x44 || data[2] != 0x33) return 0;

    final size = (data[6] & 0x7F) << 21 |
        (data[7] & 0x7F) << 14 |
        (data[8] & 0x7F) << 7 |
        (data[9] & 0x7F);

    return 10 + size;
  }

  static _Frame? _findFrame(Uint8List data, int from) {
    final limit = data.length - 4;

    for (var i = from; i < limit && i < from + 200000; i++) {
      if (data[i] != 0xFF || (data[i + 1] & 0xE0) != 0xE0) continue;

      final frame = _parseFrame(data, i);
      if (frame != null) return frame;
    }
    return null;
  }

  static _Frame? _parseFrame(Uint8List data, int offset) {
    final b1 = data[offset + 1];
    final b2 = data[offset + 2];
    final b3 = data[offset + 3];

    final versionBits = (b1 >> 3) & 0x03;
    final layerBits = (b1 >> 1) & 0x03;
    if (versionBits == 1 || layerBits != 1) return null;

    final bitrateIndex = (b2 >> 4) & 0x0F;
    final rateIndex = (b2 >> 2) & 0x03;
    if (bitrateIndex == 0 || bitrateIndex == 15 || rateIndex == 3) return null;

    final version = versionBits == 3 ? 1 : 2;
    final rates = switch (versionBits) {
      3 => _ratesV1,
      2 => _ratesV2,
      _ => _ratesV25,
    };

    final sampleRate = rates[rateIndex];
    if (sampleRate == 0) return null;

    final bitrate = version == 1
        ? _bitratesV1L3[bitrateIndex]
        : _bitratesV2L3[bitrateIndex];
    if (bitrate == 0) return null;

    final channelMode = (b3 >> 6) & 0x03;

    return _Frame(
      offset: offset,
      version: version,
      bitrate: bitrate,
      sampleRate: sampleRate,
      mono: channelMode == 3,
    );
  }

  static int? _xingFrames(Uint8List data, _Frame frame) {
    final sideInfo = frame.version == 1
        ? (frame.mono ? 17 : 32)
        : (frame.mono ? 9 : 17);

    final start = frame.offset + 4 + sideInfo;
    if (start + 12 > data.length) return null;

    final tag = String.fromCharCodes(data, start, start + 4);

    if (tag == 'Xing' || tag == 'Info') {
      final flags = _uint32(data, start + 4);
      if (flags & 0x01 == 0) return null;
      return _uint32(data, start + 8);
    }

    final vbriStart = frame.offset + 4 + 32;
    if (vbriStart + 26 > data.length) return null;
    if (String.fromCharCodes(data, vbriStart, vbriStart + 4) != 'VBRI') {
      return null;
    }

    return _uint32(data, vbriStart + 14);
  }

  static int _uint32(Uint8List data, int offset) {
    if (offset + 3 >= data.length) return 0;
    return data[offset] << 24 |
        data[offset + 1] << 16 |
        data[offset + 2] << 8 |
        data[offset + 3];
  }
}

class _Frame {
  final int offset;
  final int version;
  final int bitrate;
  final int sampleRate;
  final bool mono;

  const _Frame({
    required this.offset,
    required this.version,
    required this.bitrate,
    required this.sampleRate,
    required this.mono,
  });
}
