import 'dart:typed_data';

class CoverCache {
  CoverCache._();

  static const String scheme = 'mem://';

  static final Map<String, Uint8List> _items = {};

  static bool isKey(String source) => source.startsWith(scheme);

  static String store(String owner, Uint8List bytes) {
    final key = '$scheme$owner/${bytes.length}';
    _items[key] = bytes;
    return key;
  }

  static Uint8List? get(String key) => _items[key];

  static void forget(String owner) {
    _items.removeWhere((key, _) => key.startsWith('$scheme$owner/'));
  }
}
