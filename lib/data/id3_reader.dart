import 'dart:io';
import 'dart:typed_data';

import 'id3_parser.dart';
import 'mp3_duration.dart';

class Id3Reader {
  Id3Reader._();

  static Future<AudioTags> read(File file) async {
    RandomAccessFile? handle;
    try {
      handle = await file.open();

      final header = await handle.read(Id3Parser.headerSize);
      final size = Id3Parser.tagSize(header);

      if (size > 0) {
        await handle.setPosition(0);
        final block = await handle.read(Id3Parser.headerSize + size);
        final tags = Id3Parser.parseV2(block);
        if (tags != null && !tags.isEmpty) return tags;
      }

      final length = await file.length();
      if (length < 128) return const AudioTags();

      await handle.setPosition(length - 128);
      final tail = await handle.read(128);
      return Id3Parser.parseV1(tail);
    } catch (_) {
      return const AudioTags();
    } finally {
      await handle?.close();
    }
  }

  static AudioTags readBytes(Uint8List bytes) => Id3Parser.parse(bytes);

  static Future<Duration?> duration(File file) async {
    RandomAccessFile? handle;
    try {
      handle = await file.open();
      final head = await handle.read(_probe);
      return Mp3Duration.estimate(head, await file.length());
    } catch (_) {
      return null;
    } finally {
      await handle?.close();
    }
  }

  static const int _probe = 256 * 1024;
}
