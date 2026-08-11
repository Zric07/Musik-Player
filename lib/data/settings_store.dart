import 'package:sqflite_common/sqlite_api.dart';

import 'database.dart';

class SettingsStore {
  SettingsStore._();

  static const String scanRoots = 'scan_roots';
  static const String excluded = 'excluded_roots';
  static const String speed = 'playback_speed';
  static const String equalizerBands = 'equalizer_bands';
  static const String equalizerOn = 'equalizer_on';
  static const String loudness = 'loudness_boost';

  static const String _separator = '\u0001';

  static final Map<String, String> _cache = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;

    try {
      final db = await AppDatabase.instance();
      final rows = await db.query('settings');

      _cache
        ..clear()
        ..addEntries(
          rows.map(
            (row) => MapEntry(row['key'] as String, row['value'] as String),
          ),
        );
    } catch (_) {}

    _loaded = true;
  }

  static String? text(String key) => _cache[key];

  static double number(String key, double fallback) {
    return double.tryParse(_cache[key] ?? '') ?? fallback;
  }

  static bool flag(String key, bool fallback) {
    final value = _cache[key];
    if (value == null) return fallback;
    return value == '1';
  }

  static List<String> list(String key) {
    final value = _cache[key];
    if (value == null || value.isEmpty) return const [];

    return value.split(_separator).where((item) => item.isNotEmpty).toList();
  }

  static Future<void> setText(String key, String value) async {
    _cache[key] = value;

    try {
      final db = await AppDatabase.instance();
      await db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  static Future<void> setNumber(String key, double value) {
    return setText(key, value.toString());
  }

  static Future<void> setFlag(String key, bool value) {
    return setText(key, value ? '1' : '0');
  }

  static Future<void> setList(String key, List<String> values) {
    return setText(key, values.join(_separator));
  }
}
