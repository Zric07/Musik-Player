import 'package:just_audio/just_audio.dart';

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

  static const bool supported = false;

  static double minDecibels = -15;
  static double maxDecibels = 15;

  static AudioPipeline? get pipeline => null;

  static bool get isEnabled => false;

  static double get boost => 0;

  static Future<List<EqualizerBand>> bands() async => const [];

  static Future<void> restore() async {}

  static Future<void> setEnabled(bool value) async {}

  static Future<void> setGain(int index, double gain) async {}

  static Future<void> setBoost(double decibels) async {}

  static Future<void> reset() async {}
}
