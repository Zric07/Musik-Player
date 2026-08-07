import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musik/data/id3_reader.dart';

Uint8List _syncSafe(int value) {
  return Uint8List.fromList([
    (value >> 21) & 0x7F,
    (value >> 14) & 0x7F,
    (value >> 7) & 0x7F,
    value & 0x7F,
  ]);
}

Uint8List _uint32(int value) {
  return Uint8List.fromList([
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ]);
}

Uint8List _textFrame(String id, String text, {int encoding = 0}) {
  final body = <int>[encoding];

  if (encoding == 0) {
    body.addAll(latin1.encode(text));
  } else if (encoding == 3) {
    body.addAll(utf8.encode(text));
  } else {
    body.addAll([0xFF, 0xFE]);
    for (final unit in text.codeUnits) {
      body.addAll([unit & 0xFF, (unit >> 8) & 0xFF]);
    }
  }

  return Uint8List.fromList([
    ...latin1.encode(id),
    ..._uint32(body.length),
    0,
    0,
    ...body,
  ]);
}

Uint8List _lyricsFrame(String text, {int encoding = 0}) {
  final body = <int>[
    encoding,
    ...latin1.encode('deu'),
    0,
    ...(encoding == 3 ? utf8.encode(text) : latin1.encode(text)),
  ];

  return Uint8List.fromList([
    ...latin1.encode('USLT'),
    ..._uint32(body.length),
    0,
    0,
    ...body,
  ]);
}

Uint8List _timedLyricsFrame(List<(int, String)> lines) {
  final body = <int>[
    0,
    ...latin1.encode('deu'),
    2,
    1,
    0,
  ];

  for (final (stamp, text) in lines) {
    body
      ..addAll(latin1.encode(text))
      ..add(0)
      ..addAll(_uint32(stamp));
  }

  return Uint8List.fromList([
    ...latin1.encode('SYLT'),
    ..._uint32(body.length),
    0,
    0,
    ...body,
  ]);
}

Uint8List _pictureFrame(List<int> image, {String mime = 'image/jpeg'}) {
  final body = <int>[
    0,
    ...latin1.encode(mime),
    0,
    3,
    ...latin1.encode('cover'),
    0,
    ...image,
  ];

  return Uint8List.fromList([
    ...latin1.encode('APIC'),
    ..._uint32(body.length),
    0,
    0,
    ...body,
  ]);
}

Uint8List _tag(List<Uint8List> frames, {int major = 3, int padding = 16}) {
  final payload = <int>[];
  for (final frame in frames) {
    payload.addAll(frame);
  }
  payload.addAll(List.filled(padding, 0));

  return Uint8List.fromList([
    ...latin1.encode('ID3'),
    major,
    0,
    0,
    ..._syncSafe(payload.length),
    ...payload,
  ]);
}

Uint8List _v1Tag({
  required String title,
  required String artist,
  required String album,
}) {
  List<int> field(String value, int length) {
    final bytes = latin1.encode(value).take(length).toList();
    return [...bytes, ...List.filled(length - bytes.length, 0)];
  }

  return Uint8List.fromList([
    ...latin1.encode('TAG'),
    ...field(title, 30),
    ...field(artist, 30),
    ...field(album, 30),
    ...List.filled(4, 0),
    ...List.filled(30, 0),
    0,
  ]);
}

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('id3');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  Future<File> write(String name, List<int> bytes) async {
    final file = File('${temp.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  test('liest Titel, Interpret und Album aus ID3v2.3', () async {
    final file = await write('a.mp3', [
      ..._tag([
        _textFrame('TIT2', 'Bohemian Rhapsody'),
        _textFrame('TPE1', 'Queen'),
        _textFrame('TALB', 'A Night at the Opera'),
      ]),
      ...List.filled(64, 0x55),
    ]);

    final tags = await Id3Reader.read(file);

    expect(tags.title, 'Bohemian Rhapsody');
    expect(tags.artist, 'Queen');
    expect(tags.album, 'A Night at the Opera');
  });

  test('behaelt Leerzeichen im Titel', () async {
    final file = await write('b.mp3', _tag([_textFrame('TIT2', 'Hey Jude')]));
    final tags = await Id3Reader.read(file);

    expect(tags.title, 'Hey Jude');
  });

  test('liest UTF-16 mit BOM', () async {
    final file = await write(
      'c.mp3',
      _tag([_textFrame('TIT2', 'Grüße aus Köln', encoding: 1)]),
    );

    final tags = await Id3Reader.read(file);
    expect(tags.title, 'Grüße aus Köln');
  });

  test('liest UTF-8', () async {
    final file = await write(
      'd.mp3',
      _tag([_textFrame('TPE1', 'Sigur Rós', encoding: 3)]),
    );

    final tags = await Id3Reader.read(file);
    expect(tags.artist, 'Sigur Rós');
  });

  test('liest ID3v2.4 mit syncsafe Framegroessen', () async {
    final frame = _textFrame('TIT2', 'Vier');
    final size = frame.length - 10;
    final patched = Uint8List.fromList([
      ...frame.sublist(0, 4),
      ..._syncSafe(size),
      ...frame.sublist(8),
    ]);

    final file = await write('e.mp3', _tag([patched], major: 4));
    final tags = await Id3Reader.read(file);

    expect(tags.title, 'Vier');
  });

  test('extrahiert das Cover', () async {
    final image = List<int>.generate(256, (i) => i % 256);
    final file = await write('f.mp3', _tag([_pictureFrame(image)]));

    final tags = await Id3Reader.read(file);

    expect(tags.picture, isNotNull);
    expect(tags.picture!.length, image.length);
    expect(tags.picture!.first, image.first);
    expect(tags.picture!.last, image.last);
    expect(tags.pictureMime, 'image/jpeg');
  });

  test('liest den Liedtext aus USLT', () async {
    final file = await write(
      'lyr.mp3',
      _tag([_lyricsFrame('Erste Zeile\nZweite Zeile')]),
    );

    final tags = await Id3Reader.read(file);

    expect(tags.lyrics, 'Erste Zeile\nZweite Zeile');
    expect(tags.hasLyrics, isTrue);
    expect(tags.timedLyrics, isEmpty);
  });

  test('liest den Liedtext als UTF-8 mit Umlauten', () async {
    final file = await write(
      'lyr2.mp3',
      _tag([_lyricsFrame('Grüße aus Köln', encoding: 3)]),
    );

    final tags = await Id3Reader.read(file);
    expect(tags.lyrics, 'Grüße aus Köln');
  });

  test('liest synchronisierten Text aus SYLT', () async {
    final file = await write(
      'sylt.mp3',
      _tag([
        _timedLyricsFrame([
          (0, 'Anfang'),
          (5000, 'Mitte'),
          (12500, 'Ende'),
        ]),
      ]),
    );

    final tags = await Id3Reader.read(file);

    expect(tags.timedLyrics.length, 3);
    expect(tags.timedLyrics.first.text, 'Anfang');
    expect(tags.timedLyrics.first.time, Duration.zero);
    expect(tags.timedLyrics[1].time, const Duration(seconds: 5));
    expect(tags.timedLyrics.last.time, const Duration(milliseconds: 12500));
    expect(tags.hasLyrics, isTrue);
  });

  test('meldet keinen Text wenn keiner da ist', () async {
    final file = await write('plain.mp3', _tag([_textFrame('TIT2', 'Nur Titel')]));
    final tags = await Id3Reader.read(file);

    expect(tags.hasLyrics, isFalse);
    expect(tags.lyrics, isNull);
    expect(tags.timedLyrics, isEmpty);
  });

  test('faellt auf ID3v1 zurueck', () async {
    final file = await write('g.mp3', [
      ...List.filled(512, 0x00),
      ..._v1Tag(title: 'Alt', artist: 'Band', album: 'Scheibe'),
    ]);

    final tags = await Id3Reader.read(file);

    expect(tags.title, 'Alt');
    expect(tags.artist, 'Band');
    expect(tags.album, 'Scheibe');
  });

  test('liefert leere Tags bei Datei ohne Tag', () async {
    final file = await write('h.mp3', List.filled(4096, 0x33));
    final tags = await Id3Reader.read(file);

    expect(tags.isEmpty, isTrue);
  });

  test('stuerzt bei kaputtem Tag nicht ab', () async {
    final file = await write('i.mp3', [
      ...latin1.encode('ID3'),
      3,
      0,
      0,
      0x7F,
      0x7F,
      0x7F,
      0x7F,
      1,
      2,
      3,
    ]);

    final tags = await Id3Reader.read(file);
    expect(tags.isEmpty, isTrue);
  });
}
