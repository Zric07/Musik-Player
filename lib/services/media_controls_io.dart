import 'dart:io';
import 'dart:ui';

import 'package:just_audio_background/just_audio_background.dart';
import 'package:smtc_windows/smtc_windows.dart' as smtc;

import '../models/song.dart';

class MediaControls {
  MediaControls._();

  static smtc.SMTCWindows? _windows;

  static bool get _isNotification => Platform.isAndroid || Platform.isIOS;

  static bool get _isWindows => Platform.isWindows;

  static Future<void> init() async {
    if (_isNotification) {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'de.musik.playback',
        androidNotificationChannelName: 'Wiedergabe',
        androidNotificationIcon: 'drawable/ic_notification',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationClickStartsActivity: true,
        notificationColor: const Color(0xFFE23E4E),
        preloadArtwork: true,
      );
      return;
    }

    if (_isWindows) {
      try {
        await smtc.SMTCWindows.initialize();
      } catch (_) {}
    }
  }

  static void bind({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function() onNext,
    required Future<void> Function() onPrevious,
  }) {
    if (!_isWindows || _windows != null) return;

    final smtc.SMTCWindows controls;
    try {
      controls = smtc.SMTCWindows(
        enabled: false,
        config: const smtc.SMTCConfig(
          playEnabled: true,
          pauseEnabled: true,
          nextEnabled: true,
          prevEnabled: true,
          stopEnabled: false,
          fastForwardEnabled: false,
          rewindEnabled: false,
        ),
      );
    } catch (_) {
      return;
    }

    controls.buttonPressStream.listen((button) async {
      switch (button) {
        case smtc.PressedButton.play:
          await onPlay();
        case smtc.PressedButton.pause:
          await onPause();
        case smtc.PressedButton.next:
          await onNext();
        case smtc.PressedButton.previous:
          await onPrevious();
        default:
          break;
      }
    });

    _windows = controls;
  }

  static Future<void> setSong(Song song) async {
    final controls = _windows;
    if (controls == null) return;

    try {
      await controls.updateMetadata(
        smtc.MusicMetadata(
          title: song.title,
          artist: song.artist,
          album: song.album,
          albumArtist: song.artist,
          thumbnail: song.hasCover ? Uri.file(song.cover).toString() : null,
        ),
      );
      await controls.updateTimeline(_timeline(Duration.zero, song.duration));
      await controls.enableSmtc();
    } catch (_) {}
  }

  static Future<void> setPlaying(bool playing) async {
    final controls = _windows;
    if (controls == null) return;

    try {
      await controls.setPlaybackStatus(
        playing ? smtc.PlaybackStatus.playing : smtc.PlaybackStatus.paused,
      );
    } catch (_) {}
  }

  static Future<void> setPosition(Duration position, Duration total) async {
    final controls = _windows;
    if (controls == null || total <= Duration.zero) return;

    try {
      await controls.updateTimeline(_timeline(position, total));
    } catch (_) {}
  }

  static Future<void> clear() async {
    final controls = _windows;
    if (controls == null) return;

    try {
      await controls.setPlaybackStatus(smtc.PlaybackStatus.stopped);
      await controls.disableSmtc();
    } catch (_) {}
  }

  static smtc.PlaybackTimeline _timeline(Duration position, Duration total) {
    return smtc.PlaybackTimeline(
      startTimeMs: 0,
      endTimeMs: total.inMilliseconds,
      positionMs: position.inMilliseconds,
      minSeekTimeMs: 0,
      maxSeekTimeMs: total.inMilliseconds,
    );
  }
}
