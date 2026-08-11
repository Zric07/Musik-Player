import 'dart:io';

import 'package:just_audio/just_audio.dart';

import '../data/settings_store.dart';

class EqualizerBand {
  final int index;
  final double centerFrequency;
  final double gain;

  const EqualizerBand({
    required this.index,
    required this.centerFrequency,
    required this.gain,
  });
}

class AudioEffects {
  AudioEffects._();

  static final bool supported = Platform.isAndroid;

  static final AndroidEqualizer? _equalizer =
      supported ? AndroidEqualizer() : null;

  static final AndroidLoudnessEnhancer? _loudness =
      supported ? AndroidLoudnessEnhancer() : null;

  static AndroidEqualizerParameters? _parameters;

  static double minDecibels = -15;
  static double maxDecibels = 15;

  static AudioPipeline? get pipeline {
    final equalizer = _equalizer;
    final loudness = _loudness;
    if (equalizer == null || loudness == null) return null;

    return AudioPipeline(androidAudioEffects: [loudness, equalizer]);
  }

  static bool get isEnabled => _equalizer?.enabled ?? false;

  static double get boost =>
      SettingsStore.number(SettingsStore.loudness, 0);

  static Future<List<EqualizerBand>> bands() async {
    final equalizer = _equalizer;
    if (equalizer == null) return const [];

    try {
      final parameters = _parameters ??= await equalizer.parameters;
      minDecibels = parameters.minDecibels;
      maxDecibels = parameters.maxDecibels;

      return parameters.bands
          .map(
            (band) => EqualizerBand(
              index: band.index,
              centerFrequency: band.centerFrequency,
              gain: band.gain,
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> restore() async {
    if (!supported) return;

    final on = SettingsStore.flag(SettingsStore.equalizerOn, false);
    await setEnabled(on);
    await setBoost(boost);

    final stored = SettingsStore.list(SettingsStore.equalizerBands);
    if (stored.isEmpty || !on) return;

    final available = await bands();

    for (var i = 0; i < stored.length && i < available.length; i++) {
      final gain = double.tryParse(stored[i]);
      if (gain == null) continue;
      await setGain(i, gain);
    }
  }

  static Future<void> setEnabled(bool value) async {
    final equalizer = _equalizer;
    if (equalizer == null) return;

    try {
      await equalizer.setEnabled(value);
      await SettingsStore.setFlag(SettingsStore.equalizerOn, value);
    } catch (_) {}
  }

  static Future<void> setGain(int index, double gain) async {
    final parameters = _parameters;
    if (parameters == null) return;
    if (index < 0 || index >= parameters.bands.length) return;

    try {
      await parameters.bands[index].setGain(gain);

      final gains = parameters.bands
          .map((band) => band.gain.toStringAsFixed(2))
          .toList();
      await SettingsStore.setList(SettingsStore.equalizerBands, gains);
    } catch (_) {}
  }

  static Future<void> setBoost(double decibels) async {
    final loudness = _loudness;
    if (loudness == null) return;

    try {
      await loudness.setEnabled(decibels > 0);
      await loudness.setTargetGain(decibels);
      await SettingsStore.setNumber(SettingsStore.loudness, decibels);
    } catch (_) {}
  }

  static Future<void> reset() async {
    final parameters = _parameters;
    if (parameters == null) return;

    for (var i = 0; i < parameters.bands.length; i++) {
      await setGain(i, 0);
    }
    await setBoost(0);
  }
}
