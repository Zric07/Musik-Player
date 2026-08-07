import 'package:flutter/widgets.dart';

import '../data/cover_cache.dart';
import 'file_provider.dart';

ImageProvider? coverProvider(String source) {
  if (source.isEmpty) return null;

  if (CoverCache.isKey(source)) {
    final bytes = CoverCache.get(source);
    return bytes == null ? null : MemoryImage(bytes);
  }

  return fileProvider(source);
}
