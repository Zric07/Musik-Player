import '../models/song.dart';

class MediaControls {
  MediaControls._();

  static Future<void> init() async {}

  static void bind({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function() onNext,
    required Future<void> Function() onPrevious,
  }) {}

  static Future<void> setSong(Song song) async {}

  static Future<void> setPlaying(bool playing) async {}

  static Future<void> setPosition(Duration position, Duration total) async {}

  static Future<void> clear() async {}
}
