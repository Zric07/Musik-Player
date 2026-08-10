import 'dart:async';
import 'dart:math';

import 'package:just_audio/just_audio.dart';

import '../data/library.dart';
import '../data/play_history.dart';
import '../data/player_state_store.dart';
import '../models/playback.dart';
import '../models/song.dart';

class SongService {
  static final SongService _instance = SongService._();
  factory SongService() => _instance;

  final AudioPlayer player = AudioPlayer();

  final List<Song> queue = [];

  final _queueController = StreamController<List<Song>>.broadcast();
  final _modeController = StreamController<void>.broadcast();
  final _random = Random();

  List<Song> _ordered = [];
  bool _shuffle = false;
  RepeatMode _repeat = RepeatMode.off;
  double _volume = 1;

  List<Song> _library = [];

  int _index = -1;

  bool _loading = false;

  Song? _tracked;
  Duration _listened = Duration.zero;
  DateTime? _since;
  bool _reachedEnd = false;

  SongService._() {
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && !_loading) {
        _reachedEnd = true;
        next();
      }
    });

    player.playingStream.listen((playing) {
      if (playing) {
        _since ??= DateTime.now();
      } else {
        _collect();
      }
    });
  }

  void _collect() {
    final since = _since;
    if (since == null) return;
    _listened += DateTime.now().difference(since);
    _since = null;
  }

  Future<void> _flush() async {
    _collect();

    final song = _tracked;
    final listened = _listened;
    final reachedEnd = _reachedEnd;

    _tracked = null;
    _listened = Duration.zero;
    _reachedEnd = false;

    if (song == null) return;

    final total = player.duration;
    final complete = reachedEnd ||
        (total != null &&
            total > Duration.zero &&
            listened.inMilliseconds >= total.inMilliseconds * 0.9);

    try {
      await PlayHistory.record(
        song: song,
        listened: listened,
        finished: complete,
      );
    } catch (_) {}
  }

  Song? get current =>
      _index >= 0 && _index < queue.length ? queue[_index] : null;

  int get currentIndex => _index;

  bool get hasNext =>
      _index < queue.length - 1 ||
      (_repeat == RepeatMode.all && queue.isNotEmpty);
  bool get hasPrev => _index > 0 ||
      (_repeat == RepeatMode.all && queue.isNotEmpty);

  bool get shuffle => _shuffle;
  RepeatMode get repeat => _repeat;
  double get volume => _volume;

  Stream<void> get modeStream => _modeController.stream;

  Future<void> restore(List<Song> library) async {
    if (library.isEmpty) return;

    final stored = await PlayerStateStore.load();
    if (stored == null) return;

    final byId = {for (final song in library) song.id: song};
    final songs = stored.songIds
        .map((id) => byId[id])
        .whereType<Song>()
        .toList();

    if (songs.isEmpty) return;

    _shuffle = stored.shuffle;
    _repeat = stored.repeat;
    _volume = stored.volume;

    queue
      ..clear()
      ..addAll(songs);
    _ordered = List.of(songs);
    _index = stored.index.clamp(0, songs.length - 1);

    try {
      await player.setVolume(_volume);
      await player.setLoopMode(
        _repeat == RepeatMode.one ? LoopMode.one : LoopMode.off,
      );

      _loading = true;
      await MusicLibrary.setSource(player, songs[_index]);
      if (stored.elapsed > Duration.zero) await player.seek(stored.elapsed);
      _tracked = songs[_index];
    } catch (_) {
    } finally {
      _loading = false;
    }

    _modeController.add(null);
    _notify();
  }

  Future<void> persist() async {
    if (queue.isEmpty) {
      await PlayerStateStore.clear();
      return;
    }

    try {
      await PlayerStateStore.save(
        songIds: queue.map((song) => song.id).toList(),
        index: _index < 0 ? 0 : _index,
        elapsed: player.position,
        shuffle: _shuffle,
        repeat: _repeat,
        volume: _volume,
      );
    } catch (_) {}
  }

  Stream<List<Song>> get queueStream => _queueController.stream;

  Stream<bool> get playingStream => player.playingStream;

  Stream<Duration> get positionStream => player.positionStream;

  Duration? get duration => player.duration;

  bool get isPlaying => player.playing;

  Future<void> playList(List<Song> songs, int start) async {
    _ordered = List.of(songs);

    final anchor = start >= 0 && start < songs.length ? songs[start] : null;
    final order = _shuffle ? _shuffled(_ordered, anchor) : List.of(_ordered);

    queue
      ..clear()
      ..addAll(order);

    _index = anchor == null
        ? (order.isEmpty ? -1 : 0)
        : order.indexWhere((s) => s.id == anchor.id);

    _notify();
    await _load();
  }

  List<Song> _shuffled(List<Song> songs, Song? anchor) {
    final rest = List.of(songs);
    if (anchor != null) rest.removeWhere((s) => s.id == anchor.id);
    rest.shuffle(_random);
    return anchor == null ? rest : [anchor, ...rest];
  }

  Future<void> setShuffle(bool value) async {
    if (_shuffle == value) return;
    _shuffle = value;

    final playing = current;
    if (_ordered.isEmpty) _ordered = List.of(queue);

    final order = value ? _shuffled(_ordered, playing) : List.of(_ordered);

    queue
      ..clear()
      ..addAll(order);

    _index = playing == null
        ? (order.isEmpty ? -1 : 0)
        : order.indexWhere((s) => s.id == playing.id);

    _modeController.add(null);
    _notify();
  }

  Future<void> setRepeat(RepeatMode mode) async {
    _repeat = mode;
    await player.setLoopMode(
      mode == RepeatMode.one ? LoopMode.one : LoopMode.off,
    );
    _modeController.add(null);
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    await player.setVolume(_volume);
    _modeController.add(null);
  }

  void playNext(Song song) {
    if (_index < 0) {
      queue.add(song);
    } else {
      queue.insert(_index + 1, song);
    }
    _ordered = List.of(queue);
    _notify();
  }

  void addToQueue(Song song) {
    queue.add(song);
    _ordered = List.of(queue);
    _notify();
  }

  void removeFromQueue(int i) {
    if (i < 0 || i >= queue.length) return;
    queue.removeAt(i);
    if (i < _index) _index--;
    _ordered = List.of(queue);
    _notify();
  }

  void reorderQueue(int from, int to) {
    if (from < 0 || from >= queue.length) return;
    if (to > from) to--;
    if (to < 0 || to >= queue.length) return;

    final song = queue.removeAt(from);
    queue.insert(to, song);

    if (_index == from) {
      _index = to;
    } else if (from < _index && to >= _index) {
      _index--;
    } else if (from > _index && to <= _index) {
      _index++;
    }
    _ordered = List.of(queue);
    _notify();
  }

  Future<void> next() async {
    if (queue.isEmpty) return;

    if (_index >= queue.length - 1) {
      if (_repeat != RepeatMode.all) return;
      _index = 0;
    } else {
      _index++;
    }

    _notify();
    await _load();
  }

  Future<void> prev() async {
    if (queue.isEmpty) return;

    if (_index <= 0) {
      if (_repeat != RepeatMode.all) return;
      _index = queue.length - 1;
    } else {
      _index--;
    }

    _notify();
    await _load();
  }

  Future<void> jumpTo(int i) async {
    if (i < 0 || i >= queue.length) return;
    _index = i;
    _notify();
    await _load();
  }

  Future<void> resume() => player.play();
  Future<void> pause() => player.pause();
  Future<void> seek(Duration position) => player.seek(position);

  Future<void> toggle(Song song, List<Song> list) async {
    if (current?.id != song.id) {
      await playList(list, list.indexOf(song));
    } else if (isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  bool get canImport => MusicLibrary.canImport;

  String get importLabel => MusicLibrary.importLabel;

  Future<List<Song>> getSongs() async {
    if (_library.isNotEmpty) return _library;
    return refresh();
  }

  Future<List<Song>> refresh() async {
    _library = await MusicLibrary.load();
    return _library;
  }

  Future<int> importFromDevice() async {
    final added = await MusicLibrary.import();
    if (added > 0) await refresh();
    return added;
  }

  void _notify() => _queueController.add(List.of(queue));

  Future<void> _load() async {
    final song = current;
    if (song == null) return;

    await _flush();

    _loading = true;
    try {
      await MusicLibrary.setSource(player, song);
      _tracked = song;
      await player.play();
    } catch (_) {
    } finally {
      _loading = false;
    }

    unawaited(persist());
  }
}
