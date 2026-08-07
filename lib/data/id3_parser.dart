import 'dart:convert';
import 'dart:typed_data';

class LyricLine {
  final Duration time;
  final String text;

  const LyricLine({required this.time, required this.text});
}

class AudioTags {
  final String? title;
  final String? artist;
  final String? album;
  final Uint8List? picture;
  final String? pictureMime;
  final String? lyrics;
  final List<LyricLine> timedLyrics;

  const AudioTags({
    this.title,
    this.artist,
    this.album,
    this.picture,
    this.pictureMime,
    this.lyrics,
    this.timedLyrics = const [],
  });

  bool get hasLyrics => lyrics != null || timedLyrics.isNotEmpty;

  bool get isEmpty =>
      title == null &&
      artist == null &&
      album == null &&
      picture == null &&
      !hasLyrics;
}

class Id3Parser {
  Id3Parser._();

  static const int headerSize = 10;
  static const int maxTagSize = 24 * 1024 * 1024;

  static AudioTags parse(Uint8List bytes) {
    final size = tagSize(bytes);
    if (size > 0 && bytes.length >= headerSize + size) {
      final tags = parseV2(
        Uint8List.sublistView(bytes, 0, headerSize + size),
      );
      if (tags != null && !tags.isEmpty) return tags;
    }
    return parseV1(bytes);
  }

  static int tagSize(Uint8List header) {
    if (header.length < headerSize) return 0;
    if (header[0] != 0x49 || header[1] != 0x44 || header[2] != 0x33) return 0;

    final major = header[3];
    if (major < 2 || major > 4) return 0;

    final size = _syncSafe(header, 6);
    return (size <= 0 || size > maxTagSize) ? 0 : size;
  }

  static AudioTags? parseV2(Uint8List headerAndBody) {
    if (headerAndBody.length <= headerSize) return null;

    final major = headerAndBody[3];
    final unsynchronised = (headerAndBody[5] & 0x80) != 0;

    final raw = Uint8List.sublistView(headerAndBody, headerSize);
    final data = unsynchronised ? _removeUnsynchronisation(raw) : raw;

    return major == 2 ? _parseV2_2(data) : _parseV2_3(data, major);
  }

  static AudioTags parseV1(Uint8List bytes) {
    if (bytes.length < 128) return const AudioTags();

    final block = Uint8List.sublistView(bytes, bytes.length - 128);
    if (block[0] != 0x54 || block[1] != 0x41 || block[2] != 0x47) {
      return const AudioTags();
    }

    String field(int start, int end) {
      final raw = Uint8List.sublistView(block, start, end);
      var stop = raw.length;
      while (stop > 0 && (raw[stop - 1] == 0 || raw[stop - 1] == 0x20)) {
        stop--;
      }
      return latin1.decode(Uint8List.sublistView(raw, 0, stop));
    }

    return AudioTags(
      title: _orNull(field(3, 33)),
      artist: _orNull(field(33, 63)),
      album: _orNull(field(63, 93)),
    );
  }

  static AudioTags _parseV2_3(Uint8List data, int major) {
    String? title;
    String? artist;
    String? album;
    Uint8List? picture;
    String? pictureMime;
    String? lyrics;
    var timed = const <LyricLine>[];

    var offset = 0;
    while (offset + 10 <= data.length) {
      final id = String.fromCharCodes(data, offset, offset + 4);
      if (id.codeUnitAt(0) == 0) break;

      final size = major == 4
          ? _syncSafe(data, offset + 4)
          : _uint32(data, offset + 4);

      if (size <= 0 || offset + 10 + size > data.length) break;

      final frame = Uint8List.sublistView(
        data,
        offset + 10,
        offset + 10 + size,
      );

      switch (id) {
        case 'TIT2':
          title ??= _decodeText(frame);
        case 'TPE1':
          artist ??= _decodeText(frame);
        case 'TALB':
          album ??= _decodeText(frame);
        case 'APIC':
          if (picture == null) {
            final image = _decodePicture(frame);
            picture = image?.bytes;
            pictureMime = image?.mime;
          }
        case 'USLT':
          lyrics ??= _decodePlainLyrics(frame);
        case 'SYLT':
          if (timed.isEmpty) timed = _decodeTimedLyrics(frame);
      }

      offset += 10 + size;
    }

    return AudioTags(
      title: title,
      artist: artist,
      album: album,
      picture: picture,
      pictureMime: pictureMime,
      lyrics: lyrics,
      timedLyrics: timed,
    );
  }

  static AudioTags _parseV2_2(Uint8List data) {
    String? title;
    String? artist;
    String? album;
    Uint8List? picture;
    String? pictureMime;
    String? lyrics;
    var timed = const <LyricLine>[];

    var offset = 0;
    while (offset + 6 <= data.length) {
      final id = String.fromCharCodes(data, offset, offset + 3);
      if (id.codeUnitAt(0) == 0) break;

      final size =
          (data[offset + 3] << 16) | (data[offset + 4] << 8) | data[offset + 5];

      if (size <= 0 || offset + 6 + size > data.length) break;

      final frame = Uint8List.sublistView(data, offset + 6, offset + 6 + size);

      switch (id) {
        case 'TT2':
          title ??= _decodeText(frame);
        case 'TP1':
          artist ??= _decodeText(frame);
        case 'TAL':
          album ??= _decodeText(frame);
        case 'PIC':
          if (picture == null) {
            final image = _decodeLegacyPicture(frame);
            picture = image?.bytes;
            pictureMime = image?.mime;
          }
        case 'ULT':
          lyrics ??= _decodePlainLyrics(frame);
        case 'SLT':
          if (timed.isEmpty) timed = _decodeTimedLyrics(frame);
      }

      offset += 6 + size;
    }

    return AudioTags(
      title: title,
      artist: artist,
      album: album,
      picture: picture,
      pictureMime: pictureMime,
      lyrics: lyrics,
      timedLyrics: timed,
    );
  }

  static String? _decodeText(Uint8List frame) {
    if (frame.isEmpty) return null;

    final encoding = frame[0];
    final body = Uint8List.sublistView(frame, 1);

    return _orNull(_decode(body, encoding));
  }

  static String? _decodePlainLyrics(Uint8List frame) {
    if (frame.length < 5) return null;

    final encoding = frame[0];
    final step = (encoding == 1 || encoding == 2) ? 2 : 1;

    final descriptorEnd = _indexOfZero(frame, 4, step);
    if (descriptorEnd < 0) return null;

    final start = descriptorEnd + step;
    if (start >= frame.length) return null;

    final text = _decode(Uint8List.sublistView(frame, start), encoding);
    final trimmed = text.replaceAll('\r\n', '\n').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<LyricLine> _decodeTimedLyrics(Uint8List frame) {
    if (frame.length < 7) return const [];

    final encoding = frame[0];
    final timeFormat = frame[4];
    if (timeFormat != 2) return const [];

    final step = (encoding == 1 || encoding == 2) ? 2 : 1;

    final descriptorEnd = _indexOfZero(frame, 6, step);
    if (descriptorEnd < 0) return const [];

    var cursor = descriptorEnd + step;
    final lines = <LyricLine>[];

    while (cursor + step + 4 <= frame.length) {
      final textEnd = _indexOfZero(frame, cursor, step);
      if (textEnd < 0) break;

      final raw = _decode(
        Uint8List.sublistView(frame, cursor, textEnd),
        encoding,
      );

      cursor = textEnd + step;
      if (cursor + 4 > frame.length) break;

      final stamp = _uint32(frame, cursor);
      cursor += 4;

      final text = raw.replaceAll('\r', '').replaceAll('\n', '').trim();
      if (text.isEmpty) continue;

      lines.add(
        LyricLine(time: Duration(milliseconds: stamp), text: text),
      );
    }

    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }

  static _Picture? _decodePicture(Uint8List frame) {
    if (frame.length < 4) return null;

    final encoding = frame[0];
    var cursor = 1;

    final mimeEnd = _indexOfZero(frame, cursor, 1);
    if (mimeEnd < 0) return null;
    final mime = latin1.decode(Uint8List.sublistView(frame, cursor, mimeEnd));

    cursor = mimeEnd + 1;
    if (cursor >= frame.length) return null;
    cursor++;

    final step = (encoding == 1 || encoding == 2) ? 2 : 1;
    final descEnd = _indexOfZero(frame, cursor, step);
    if (descEnd < 0) return null;

    final start = descEnd + step;
    if (start >= frame.length) return null;

    return _Picture(
      bytes: Uint8List.fromList(Uint8List.sublistView(frame, start)),
      mime: mime.isEmpty ? 'image/jpeg' : mime,
    );
  }

  static _Picture? _decodeLegacyPicture(Uint8List frame) {
    if (frame.length < 6) return null;

    final encoding = frame[0];
    final format = String.fromCharCodes(frame, 1, 4).toUpperCase();

    final step = (encoding == 1 || encoding == 2) ? 2 : 1;
    final descEnd = _indexOfZero(frame, 5, step);
    if (descEnd < 0) return null;

    final start = descEnd + step;
    if (start >= frame.length) return null;

    return _Picture(
      bytes: Uint8List.fromList(Uint8List.sublistView(frame, start)),
      mime: format == 'PNG' ? 'image/png' : 'image/jpeg',
    );
  }

  static int _indexOfZero(Uint8List data, int from, int step) {
    if (step == 1) {
      for (var i = from; i < data.length; i++) {
        if (data[i] == 0) return i;
      }
      return -1;
    }

    for (var i = from; i + 1 < data.length; i += 2) {
      if (data[i] == 0 && data[i + 1] == 0) return i;
    }
    return -1;
  }

  static String _decode(Uint8List body, int encoding) {
    var end = body.length;
    while (end > 0 && body[end - 1] == 0) {
      end--;
    }
    final trimmed = Uint8List.sublistView(body, 0, end);

    try {
      switch (encoding) {
        case 1:
          return _decodeUtf16(trimmed, null);
        case 2:
          return _decodeUtf16(trimmed, true);
        case 3:
          return utf8.decode(trimmed, allowMalformed: true);
      }
    } catch (_) {
      return '';
    }

    return latin1.decode(trimmed, allowInvalid: true);
  }

  static String _decodeUtf16(Uint8List data, bool? bigEndian) {
    var offset = 0;
    var isBig = bigEndian ?? false;

    if (bigEndian == null && data.length >= 2) {
      if (data[0] == 0xFF && data[1] == 0xFE) {
        isBig = false;
        offset = 2;
      } else if (data[0] == 0xFE && data[1] == 0xFF) {
        isBig = true;
        offset = 2;
      }
    }

    final units = <int>[];
    for (var i = offset; i + 1 < data.length; i += 2) {
      units.add(
        isBig ? (data[i] << 8) | data[i + 1] : (data[i + 1] << 8) | data[i],
      );
    }

    return String.fromCharCodes(units);
  }

  static Uint8List _removeUnsynchronisation(Uint8List data) {
    final out = <int>[];
    for (var i = 0; i < data.length; i++) {
      out.add(data[i]);
      if (data[i] == 0xFF && i + 1 < data.length && data[i + 1] == 0x00) {
        i++;
      }
    }
    return Uint8List.fromList(out);
  }

  static int _syncSafe(Uint8List data, int offset) {
    if (offset + 3 >= data.length) return 0;
    return (data[offset] & 0x7F) << 21 |
        (data[offset + 1] & 0x7F) << 14 |
        (data[offset + 2] & 0x7F) << 7 |
        (data[offset + 3] & 0x7F);
  }

  static int _uint32(Uint8List data, int offset) {
    if (offset + 3 >= data.length) return 0;
    return data[offset] << 24 |
        data[offset + 1] << 16 |
        data[offset + 2] << 8 |
        data[offset + 3];
  }

  static String? _orNull(String value) {
    final trimmed = value.replaceAll('\u0000', '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _Picture {
  final Uint8List bytes;
  final String mime;

  const _Picture({required this.bytes, required this.mime});
}
