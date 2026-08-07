import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/playlist.dart';
import '../widgets/cover_source.dart';


class PaletteService {
  static final PaletteService _instance = PaletteService._();
  factory PaletteService() => _instance;
  PaletteService._();

  static const int _sampleSize = 72;

  final Map<String, Color> _cache = {};

  Color? peek(Playlist playlist) {
    if (!playlist.hasCover) return AppColors.coverEmpty;
    return _cache[playlist.cover];
  }

  Future<Color> forPlaylist(Playlist playlist) async {
    if (!playlist.hasCover) return AppColors.coverEmpty;

    final key = playlist.cover;
    final cached = _cache[key];
    if (cached != null) return cached;

    final source = coverProvider(key);
    if (source == null) return AppColors.coverEmpty;

    try {
      final provider = ResizeImage(
        source,
        width: _sampleSize,
        height: _sampleSize,
        allowUpscaling: false,
      );

      final image = await _resolve(provider);
      final color = await _extract(image);

      _cache[key] = color;
      return color;
    } catch (_) {
      return AppColors.coverEmpty;
    }
  }

  void forget(Playlist playlist) {
    _cache.removeWhere((key, _) => key.contains(playlist.id));
  }

  Future<ui.Image> _resolve(ImageProvider provider) {
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(ImageConfiguration.empty);

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (error, stack) {
        if (!completer.isCompleted) completer.completeError(error);
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
    return completer.future.timeout(const Duration(seconds: 10));
  }

  Future<Color> _extract(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return AppColors.coverEmpty;

    final pixels = data.buffer.asUint8List();
    final counts = <int, int>{};
    var total = 0;

    for (var i = 0; i + 3 < pixels.length; i += 4) {
      if (pixels[i + 3] < 128) continue;

      final key =
          ((pixels[i] >> 3) << 10) |
          ((pixels[i + 1] >> 3) << 5) |
          (pixels[i + 2] >> 3);

      counts[key] = (counts[key] ?? 0) + 1;
      total++;
    }

    if (total == 0) return AppColors.coverEmpty;

    var bestKey = -1;
    var bestScore = 0.0;
    var plainKey = -1;
    var plainCount = 0;

    counts.forEach((key, count) {
      if (count > plainCount) {
        plainCount = count;
        plainKey = key;
      }

      final hsl = HSLColor.fromColor(_colorOf(key));
      if (hsl.lightness < 0.10 || hsl.lightness > 0.92) return;

      final share = count / total;
      final score = share * (0.30 + hsl.saturation * 1.7);

      if (score > bestScore) {
        bestScore = score;
        bestKey = key;
      }
    });

    if (bestKey < 0) bestKey = plainKey;
    if (bestKey < 0) return AppColors.coverEmpty;

    return AppColors.headerSeed(_colorOf(bestKey));
  }

  Color _colorOf(int key) {
    final r = ((key >> 10) & 0x1F) << 3 | 4;
    final g = ((key >> 5) & 0x1F) << 3 | 4;
    final b = (key & 0x1F) << 3 | 4;
    return Color.fromARGB(255, r, g, b);
  }
}
