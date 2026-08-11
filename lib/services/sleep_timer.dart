import 'dart:async';

class SleepTimer {
  SleepTimer._();

  static Timer? _ticker;
  static DateTime? _endsAt;
  static bool _afterSong = false;

  static final _controller = StreamController<Duration?>.broadcast();

  static Stream<Duration?> get stream => _controller.stream;

  static bool get isRunning => _endsAt != null || _afterSong;

  static bool get stopsAfterSong => _afterSong;

  static Duration? get remaining {
    final end = _endsAt;
    if (end == null) return null;

    final left = end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  static void start(Duration duration, Future<void> Function() onElapsed) {
    cancel();
    if (duration <= Duration.zero) return;

    _endsAt = DateTime.now().add(duration);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = remaining;
      if (left == null) return;

      _controller.add(left);
      if (left > Duration.zero) return;

      cancel();
      onElapsed();
    });

    _controller.add(duration);
  }

  static void startAfterSong() {
    cancel();
    _afterSong = true;
    _controller.add(null);
  }

  static Future<void> songFinished(Future<void> Function() onElapsed) async {
    if (!_afterSong) return;

    cancel();
    await onElapsed();
  }

  static void cancel() {
    _ticker?.cancel();
    _ticker = null;
    _endsAt = null;
    _afterSong = false;
    _controller.add(null);
  }
}
