import 'dart:convert';
import 'dart:typed_data';

import 'id3_parser.dart';

class Id3Writer {
  Id3Writer._();

  static Uint8List apply(Uint8List file, AudioTags tags) {
    final audio = _audioOnly(file);
    final frames = <int>[];

    _addText(frames, 'TIT2', tags.title);
    _addText(frames, 'TPE1', tags.artist);
    _addText(frames, 'TALB', tags.album);
    _addLyrics(frames, tags.lyrics);
    _addPicture(frames, tags.picture, tags.pictureMime);

    if (frames.isEmpty) return audio;

    final padding = List<int>.filled(1024, 0);
    final body = [...frames, ...padding];

    final header = <int>[
      0x49, 0x44, 0x33,
      4, 0,
      0,
      ..._syncSafe(body.length),
    ];

    return Uint8List.fromList([...header, ...body, ...audio]);
  }

  static Uint8List _audioOnly(Uint8List file) {
    final size = Id3Parser.tagSize(file);
    final start = size > 0 ? Id3Parser.headerSize + size : 0;

    if (start >= file.length) return Uint8List(0);
    return Uint8List.sublistView(file, start);
  }

  static void _addText(List<int> out, String id, String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return;

    final body = <int>[3, ...utf8.encode(text)];
    _addFrame(out, id, body);
  }

  static void _addLyrics(List<int> out, String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return;

    final body = <int>[
      3,
      0x64, 0x65, 0x75,
      0,
      ...utf8.encode(text),
    ];

    _addFrame(out, 'USLT', body);
  }

  static void _addPicture(List<int> out, Uint8List? picture, String? mime) {
    if (picture == null || picture.isEmpty) return;

    final type = (mime == null || mime.isEmpty) ? 'image/jpeg' : mime;

    final body = <int>[
      0,
      ...latin1.encode(type),
      0,
      3,
      0,
      ...picture,
    ];

    _addFrame(out, 'APIC', body);
  }

  static void _addFrame(List<int> out, String id, List<int> body) {
    out
      ..addAll(ascii.encode(id))
      ..addAll(_syncSafe(body.length))
      ..addAll([0, 0])
      ..addAll(body);
  }

  static List<int> _syncSafe(int value) {
    return [
      value >> 21 & 0x7F,
      value >> 14 & 0x7F,
      value >> 7 & 0x7F,
      value & 0x7F,
    ];
  }
}
