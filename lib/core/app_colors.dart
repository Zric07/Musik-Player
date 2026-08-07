import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const bg = Color(0xFF121212);
  static const sidebar = Color(0xFF000000);
  static const surface = Color(0xFF181818);
  static const surfaceHi = Color(0xFF242424);
  static const surfaceTop = Color(0xFF2A2A2A);

  static const accent = Color(0xFFE23E4E);
  static const accentBright = Color(0xFFF25767);
  static const onAccent = Color(0xFFFFFFFF);

  static const text = Color(0xFFFFFFFF);
  static const textDim = Color(0xFFB3B3B3);
  static const textFaint = Color(0xFF7A7A7A);

  static const coverEmpty = Color(0xFF333333);

  static const hairline = Color(0x14FFFFFF);
  static const hairlineStrong = Color(0x24FFFFFF);
  static const danger = Color(0xFFFF8A80);

  static Color headerSeed(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(hsl.lightness.clamp(0.20, 0.52))
        .withSaturation(hsl.saturation.clamp(0.0, 0.72))
        .toColor();
  }

  static LinearGradient headerGradient(Color seed) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.alphaBlend(seed.withValues(alpha: 0.55), bg),
        Color.alphaBlend(seed.withValues(alpha: 0.18), bg),
        bg,
      ],
      stops: const [0.0, 0.45, 1.0],
    );
  }

  static LinearGradient tileGradient(Color seed) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [seed, Color.alphaBlend(Colors.black54, seed)],
    );
  }

  static const covers = <Color>[
    Color(0xFF1DB954),
    Color(0xFF2D46B9),
    Color(0xFFE13300),
    Color(0xFF8D67AB),
    Color(0xFFBA5D07),
    Color(0xFF148A08),
    Color(0xFFE8115B),
    Color(0xFF0D73EC),
  ];

  static Color forKey(String key) {
    if (key.isEmpty) return covers.first;
    var sum = 0;
    for (final code in key.codeUnits) {
      sum = (sum * 31 + code) & 0x7FFFFFFF;
    }
    return covers[sum % covers.length];
  }
}
